#!/bin/bash
#
# First-boot / every-boot preparation for the systemd-managed multi-node
# WarehousePG image. Runs as gpadmin via warehousepg.service's ExecStartPre,
# on EVERY container (coordinator, standby, seg1, seg2, gpfdist) -- they all
# share the same image, and branch on `hostname`.
#
# Unlike the tail-based cmd.sh this does NOT start sshd (systemd owns
# sshd.service, and PermitRootLogin / MaxStartups / MaxSessions are baked
# into /etc/ssh/sshd_config at image build time instead of passed as
# runtime flags) and does NOT run gpinitsystem/gpstart/gpfdist (that's
# warehousepg-start.sh, the unit's ExecStart) and does NOT "tail -f /dev/null".
#
# It sets up: gpadmin+root passwordless ssh (self-trust), and pushes ssh
# keys to the segment hosts (hostfile_ssh_whpginitsystem) so gpinitsystem
# on the coordinator can reach them -- this is the same key exchange dance
# cmd.sh always did, just without the sshd bootstrap.
#
# Deliberately NOT `set -e`: the ssh-copy-id retry loops below expect their
# command to fail transiently and retry, and `set -e` would abort the whole
# script on the very first failed attempt before the retry logic ever runs
# (a plain failing command inside a loop body is not exempt from `set -e`,
# only commands in if/while/&&/|| test position are). Real failures use
# explicit `exit 1` instead, same as the original cmd.sh.

if [ "$EUID" -eq 0 ]; then
    echo "warehousepg-setup.sh must run as gpadmin, not root" >&2
    exit 1
fi

WHPG_HOME="/usr/local/greenplum-db"
WHPG_USER="gpadmin"
DATA_DIR="/whpgdata"
MASTER_DATA_DIR="${DATA_DIR}/master"
STANDBY_DATA_DIR="${DATA_DIR}/standby"
SEGMENT1_DATA_DIR="${DATA_DIR}/segments/whpgdata1"
SEGMENT2_DATA_DIR="${DATA_DIR}/segments/whpgdata2"
MIRROR1_DATA_DIR="${DATA_DIR}/mirrors/whpgdata1"
MIRROR2_DATA_DIR="${DATA_DIR}/mirrors/whpgdata2"
HOSTNAME=$(hostname)
# THIS IS UNSAFE AND NOT FOR PRODUCTION! matches the password baked into the
# image via `chpasswd` in the Dockerfile, used only for the initial
# ssh-copy-id handshake before key-based auth takes over.
PASSWORD="whpg5432"

# NOTE: deliberately NOT pre-creating ${STANDBY_DATA_DIR} -- unlike
# gpinitsystem (coordinator's own init, which tolerates a pre-existing
# empty data dir), gpinitstandby refuses outright if the standby's data
# directory already exists ("Data directory already exists on host
# standby" / "Error initializing standby coordinator: coordinator data
# directory exists"), even if it's empty. Let gpinitstandby create it.
sudo mkdir -p ${MASTER_DATA_DIR} ${SEGMENT1_DATA_DIR} ${SEGMENT2_DATA_DIR} ${MIRROR1_DATA_DIR} ${MIRROR2_DATA_DIR}
sudo chown -R ${WHPG_USER}:${WHPG_USER} ${DATA_DIR}

# gpadmin passwordless ssh (self-trust)
mkdir -p /home/${WHPG_USER}/.ssh
if ! test -f /home/${WHPG_USER}/.ssh/id_rsa; then
    ssh-keygen -q -t rsa -b 2048 -f /home/${WHPG_USER}/.ssh/id_rsa -N ""
fi
if ! grep -qf /home/${WHPG_USER}/.ssh/id_rsa.pub /home/${WHPG_USER}/.ssh/authorized_keys 2>/dev/null; then
    cat /home/${WHPG_USER}/.ssh/id_rsa.pub >> /home/${WHPG_USER}/.ssh/authorized_keys
fi
chmod 0700 /home/${WHPG_USER}/.ssh
chmod 0600 /home/${WHPG_USER}/.ssh/authorized_keys
chmod 0644 /home/${WHPG_USER}/.ssh/id_rsa.pub
chmod 0600 /home/${WHPG_USER}/.ssh/id_rsa

for h in 127.0.0.1 localhost ${HOSTNAME}; do
    if ! ssh-keygen -F "$h" > /dev/null 2>&1; then
        ssh-keyscan "$h" >> /home/${WHPG_USER}/.ssh/known_hosts 2> /dev/null || true
    fi
done

# root passwordless ssh (self-trust) -- kept for parity with the tail-based
# lab, which sets this up for administrative gpssh/backup tooling
sudo mkdir -p /root/.ssh
if ! sudo test -f /root/.ssh/id_rsa; then
    sudo -- sh -c 'ssh-keygen -q -t rsa -b 2048 -f /root/.ssh/id_rsa -N ""'
fi
sudo -- sh -c 'cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys'
sudo chmod 0700 /root/.ssh
sudo chmod 0600 /root/.ssh/authorized_keys
sudo chmod 0644 /root/.ssh/id_rsa.pub
sudo chmod 0600 /root/.ssh/id_rsa
sudo chown -R root:root /root/.ssh

for h in 127.0.0.1 ${HOSTNAME}; do
    if ! sudo ssh-keygen -F "$h" > /dev/null 2>&1; then
        sudo -- sh -c "ssh-keyscan '$h' >> /root/.ssh/known_hosts 2> /dev/null" || true
    fi
done

# WarehousePG-bundled Python (EDB's own edb-python27, no dev headers
# bundled) needs psycopg2 + psutil for gpstart/gpinitsystem (only actually
# used on the coordinator, but harmless everywhere). Install the
# "-binary"/prebuilt-wheel forms so pip never needs to compile from source.
source ${WHPG_HOME}/greenplum_path.sh
for module in psycopg2:psycopg2-binary psutil:psutil; do
    import_name="${module%%:*}"
    pip_name="${module##*:}"
    if ! python -c "import ${import_name}" >/dev/null 2>&1; then
        echo "Python module '${import_name}' not found - installing ..."
        sudo bash -c ". ${WHPG_HOME}/greenplum_path.sh && python -m pip install ${pip_name}" 2>/dev/null || true
    fi
done

# All 5 containers boot in parallel and reach this ssh-bootstrap step at
# roughly the same time, so every node gets a burst of concurrent
# unauthenticated ssh-copy-id connections from the other 4 (key-probe +
# install, for both gpadmin and root, plus retries). Under emulation
# (linux/amd64 via Rosetta on Apple Silicon) this saturates the CPU and
# handshakes get reset/dropped. Stagger + generous retries absorb the storm
# (same hardening already proven in the standby-mirrors lab's cmd.sh).
JITTER=$(( RANDOM % 8 ))
echo "Staggering ssh bootstrap by ${JITTER}s to reduce the startup storm ..."
sleep ${JITTER}

# loop over all segment hosts, and:
#  - check the host is reachable (wait up to 120 seconds)
#  - wait for sshd on that host
#  - push our gpadmin + root ssh keys to it
SSH_HOSTFILE="/home/${WHPG_USER}/hostfile_ssh_whpginitsystem"
while IFS= read -r host; do
    [[ -z "${host}" ]] && continue

    host_available=0
    for ((i=0; i<120; i++)); do
        if ping -c 1 -W 1 "${host}" >/dev/null 2>&1; then
            host_available=1
            break
        fi
        sleep 1
    done
    if [ "${host_available}" -eq 0 ]; then
        echo "Host ${host} is not available!"
        exit 1
    fi

    ssh_available=0
    for ((i=0; i<120; i++)); do
        if nc -z "${host}" "22" >/dev/null 2>&1; then
            ssh_available=1
            break
        fi
        sleep 1
    done
    if [ "${ssh_available}" -eq 0 ]; then
        echo "sshd on host ${host} is not available!"
        exit 1
    fi

    ssh-keygen -F ${host} > /dev/null 2>&1 || ssh-keyscan ${host} >> /home/${WHPG_USER}/.ssh/known_hosts 2> /dev/null
    sudo ssh-keygen -F ${host} > /dev/null 2>&1 || sudo -- sh -c "ssh-keyscan ${host} >> /root/.ssh/known_hosts 2> /dev/null"

    echo "Adding ssh keys for user ${WHPG_USER} to host ${host}"
    ssh_max_attempts=40
    ssh_attempt_num=1
    ssh_operation_successful=false
    while [ $ssh_attempt_num -le $ssh_max_attempts ]; do
        sshpass -p "${PASSWORD}" ssh-copy-id -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${WHPG_USER}@${host}" > /tmp/add-ssh-keys-user-${ssh_attempt_num}.log 2>&1
        exit_status=$?
        if [ "$exit_status" -eq 0 ]; then
            ssh_operation_successful=true
            break
        fi
        sleep 2
        ssh_attempt_num=$((ssh_attempt_num + 1))
    done
    if [ "$ssh_operation_successful" = false ]; then
        echo "ERROR: Adding keys for user ${WHPG_USER} to host ${host} failed after ${ssh_attempt_num} attempts!"
        cat /tmp/add-ssh-keys-user-*.log
        exit 1
    fi

    echo "Adding ssh keys for user root to host ${host}"
    sudo chown -R root:root /etc/ssh/
    # the chown above also strips the host keys' ssh_keys group, which
    # this OpenSSH build treats as "too open" and refuses to load ("no
    # hostkeys available -- exiting"), killing every ssh connection
    # (including self-host) at kex before auth even starts. Restore it.
    sudo chgrp ssh_keys /etc/ssh/ssh_host_*_key
    sudo chmod 0640 /etc/ssh/ssh_host_*_key
    ssh_max_attempts=40
    ssh_attempt_num=1
    ssh_operation_successful=false
    while [ $ssh_attempt_num -le $ssh_max_attempts ]; do
        sudo sh -c 'sshpass -p "'${PASSWORD}'" ssh-copy-id -o StrictHostKeyChecking=no -o ConnectTimeout=10 "root@'${host}'" > /tmp/add-ssh-keys-root-'${ssh_attempt_num}'.log 2>&1'
        exit_status=$?
        if [ "$exit_status" -eq 0 ]; then
            ssh_operation_successful=true
            break
        fi
        sleep 2
        ssh_attempt_num=$((ssh_attempt_num + 1))
    done
    if [ "$ssh_operation_successful" = false ]; then
        echo "ERROR: Adding keys for user root to host ${host} failed after ${ssh_attempt_num} attempts!"
        sudo cat /tmp/add-ssh-keys-root-*.log
        exit 1
    fi
done < ${SSH_HOSTFILE}

# converge check: wait until every segment host actually appears in our
# authorized_keys (they push to us just as we push to them, concurrently)
SSH_HOSTS=$(cat "${SSH_HOSTFILE}")
SSH_ALL_HOSTS_FOUND=1
for i in {1..120}; do
    SSH_ALL_HOSTS_FOUND=0
    for SSH_HOSTNAME in ${SSH_HOSTS}; do
        if ! grep -q "@${SSH_HOSTNAME}" "/home/${WHPG_USER}/.ssh/authorized_keys"; then
            SSH_ALL_HOSTS_FOUND=1
            break
        fi
    done
    if [ ${SSH_ALL_HOSTS_FOUND} -eq 0 ]; then
        echo "SUCCESS: All host keys confirmed after ${i} attempts."
        break
    fi
    sleep 1
done
if [ $SSH_ALL_HOSTS_FOUND -ne 0 ]; then
    echo "ERROR: Not all hosts were confirmed in authorized_keys after 120 attempts"
    exit 1
fi

echo "warehousepg-setup.sh: pre-flight complete on $(hostname)"
