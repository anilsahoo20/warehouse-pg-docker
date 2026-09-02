#!/bin/bash
#
# First-boot preparation for the systemd-managed WarehousePG image.
#
# Runs as gpadmin via the warehousepg.service "ExecStartPre".
# Unlike the tail-based cmd.sh this does NOT start sshd (systemd owns
# sshd.service) and does NOT start the database (the unit's ExecStart
# runs gpinitsystem/gpstart) and does NOT "tail -f /dev/null".
#
# It only sets up what gpinitsystem/gpstart need: passwordless ssh from
# gpadmin to localhost, and the WarehousePG-bundled Python modules.

set -e

# must run as gpadmin, never root
if [ "$EUID" -eq 0 ]; then
    echo "warehousepg-setup.sh must run as gpadmin, not root" >&2
    exit 1
fi

WHPG_HOME="/usr/local/greenplum-db"
WHPG_USER="gpadmin"
DATA_DIR="/whpgdata"
HOSTNAME=$(hostname)

# data dirs are created in the Dockerfile; recreate in case /whpgdata is a
# Docker-mounted (initially empty) volume
sudo mkdir -p ${DATA_DIR}/master ${DATA_DIR}/segments/whpgdata1 ${DATA_DIR}/segments/whpgdata2
sudo chown -R ${WHPG_USER}:${WHPG_USER} ${DATA_DIR}

# passwordless ssh for gpadmin to localhost (required by gpinitsystem/gpstart)
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

# auto-accept host keys for localhost / 127.0.0.1 / hostname
for h in 127.0.0.1 localhost ${HOSTNAME}; do
    if ! ssh-keygen -F "$h" > /dev/null 2>&1; then
        ssh-keyscan "$h" >> /home/${WHPG_USER}/.ssh/known_hosts 2> /dev/null || true
    fi
done

# WarehousePG-bundled Python (EDB's own edb-python27, no dev headers
# bundled) needs psycopg2 + psutil for gpstart/gpinitsystem. Install the
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

# convenience: hostfile used by gpinitsystem
hostname > /home/${WHPG_USER}/hostfile_whpginitsystem

# populate ~/.bash_history with common commands for easier interactive debugging
if [ ! -f /home/${WHPG_USER}/.bash_history ]; then
    touch /home/${WHPG_USER}/.bash_history
    chown ${WHPG_USER}:${WHPG_USER} /home/${WHPG_USER}/.bash_history
    chmod 0600 /home/${WHPG_USER}/.bash_history
    echo "source /usr/local/greenplum-db/greenplum_path.sh" >> /home/${WHPG_USER}/.bash_history
    echo "psql whpgtest" >> /home/${WHPG_USER}/.bash_history
    echo "sudo /bin/bash --login" >> /home/${WHPG_USER}/.bash_history
    # single-node lab: this is the only host, always the coordinator
    echo "gpstart -a" >> /home/${WHPG_USER}/.bash_history
    echo "gpstop -a -M fast" >> /home/${WHPG_USER}/.bash_history
    echo "gpstate -a" >> /home/${WHPG_USER}/.bash_history
fi

# ensure ~/.bashrc sources greenplum_path.sh automatically on exec
if [ ! -f /home/${WHPG_USER}/.bashrc ] || ! grep -q "greenplum_path.sh" /home/${WHPG_USER}/.bashrc; then
    if [ ! -f /home/${WHPG_USER}/.bashrc ]; then
        touch /home/${WHPG_USER}/.bashrc
        chown ${WHPG_USER}:${WHPG_USER} /home/${WHPG_USER}/.bashrc
        chmod 0644 /home/${WHPG_USER}/.bashrc
    fi
    echo "source /usr/local/greenplum-db/greenplum_path.sh" >> /home/${WHPG_USER}/.bashrc
fi

# export MASTER_DATA_DIRECTORY so gpstate/gpstart/gpstop work on interactive login
# without needing to pass -d -- single-node lab, this is the only host,
# always the coordinator
if ! grep -q "export MASTER_DATA_DIRECTORY=" /home/${WHPG_USER}/.bashrc 2>/dev/null; then
    echo "export MASTER_DATA_DIRECTORY=/whpgdata/master/whpgsne-1" >> /home/${WHPG_USER}/.bashrc
fi


# Docker Desktop's "Exec" tab runs `docker exec -it <c> /bin/sh`. On this
# image /bin/sh is bash invoked under the name "sh", and an interactive
# sh-named bash does NOT read ~/.bashrc -- per POSIX sh-compat startup
# rules it reads the file named by $ENV instead. A plain `docker exec -it
# <c> bash` *does* read ~/.bashrc. So the gpadmin auto-hop has to fire
# from both places; the shared, root-only-guarded logic lives in
# /etc/whpg-root-autohop.sh (baked into the image; wired up for the sh
# case via `ENV ENV=...` in the Dockerfile) so it stays safe even though
# $ENV applies to every user's sh session in the container, not just root's.
if ! sudo grep -q "whpg-root-autohop.sh" /root/.bashrc 2>/dev/null; then
    echo ". /etc/whpg-root-autohop.sh" | sudo tee -a /root/.bashrc >/dev/null
fi

echo "warehousepg-setup.sh: pre-flight complete"
