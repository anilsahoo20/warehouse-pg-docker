#!/bin/bash
#
# Post-start hook for warehousepg.service (runs as gpadmin). Only does
# anything on the coordinator -- DEV/LAB ONLY: opens trust access over the
# container network so teammates can connect through the mapped host port.
# Do NOT do this in production.

set -e

HOSTNAME=$(hostname)
if [ "${HOSTNAME}" != "coordinator" ]; then
    exit 0
fi

WHPG_HOME="/usr/local/greenplum-db"
COORDINATOR_DATA_DIR="/whpgdata/coordinator/whpgmne-1"
HBAFILE="${COORDINATOR_DATA_DIR}/pg_hba.conf"
HBALINE="host     all         all             0.0.0.0/0       trust"

source ${WHPG_HOME}/greenplum_path.sh

if ! grep -Fq "${HBALINE}" "${HBAFILE}"; then
    echo "Enabling trust access in pg_hba.conf ..."
    sed -i '/# replication privilege./a\host     all         all             0.0.0.0\/0       trust' "${HBAFILE}"
    gpstop -u -d "${COORDINATOR_DATA_DIR}"
fi
