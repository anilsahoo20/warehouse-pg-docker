#!/bin/bash
#
# Post-start hook for warehousepg.service (runs as gpadmin).
#
# DEV/LAB ONLY: opens trust access over the container network so teammates
# can connect through the mapped host port. Do NOT do this in production.

set -e

WHPG_HOME="/usr/local/greenplum-db"
MASTER_DATA_DIR="/whpgdata/master/whpgsne-1"
HBAFILE="${MASTER_DATA_DIR}/pg_hba.conf"
HBALINE="host     all         all             0.0.0.0/0       trust"

source ${WHPG_HOME}/greenplum_path.sh

if ! grep -Fq "${HBALINE}" "${HBAFILE}"; then
    echo "Enabling trust access in pg_hba.conf ..."
    sed -i '/# replication privilege./a\host     all         all             0.0.0.0\/0       trust' "${HBAFILE}"
    # reload to apply pg_hba.conf changes
    gpstop -u -d "${MASTER_DATA_DIR}"
fi
