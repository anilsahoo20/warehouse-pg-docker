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

echo "warehousepg-setup.sh: pre-flight complete"
