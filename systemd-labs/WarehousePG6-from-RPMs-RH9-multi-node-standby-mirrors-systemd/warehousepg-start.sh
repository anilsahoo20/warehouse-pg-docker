#!/bin/bash
#
# Role-branching start step for warehousepg.service (runs as gpadmin, once
# warehousepg-setup.sh's ExecStartPre has finished the ssh key exchange
# across all 5 hosts).
#
# - coordinator: first boot -> gpinitsystem (with standby coordinator +
#                mirror segments); later boots -> gpstart
# - gpfdist:     start gpfdist as a background daemon (this is a oneshot
#                unit, so it must not block -- backgrounded here, killed on
#                `docker stop` via the unit's cgroup like any other child)
# - standby / seg1 / seg2: nothing to do here, gpinitsystem already brought
#   their segment/standby postgres instances up remotely via ssh from the
#   coordinator

set -e

if [ "$EUID" -eq 0 ]; then
    echo "warehousepg-start.sh must run as gpadmin, not root" >&2
    exit 1
fi

WHPG_HOME="/usr/local/greenplum-db"
WHPG_USER="gpadmin"
DATA_DIR="/whpgdata"
MASTER_DATA_DIR="${DATA_DIR}/master"
STANDBY_DATA_DIR="${DATA_DIR}/standby"
PORT=5432
HOSTNAME=$(hostname)

case "${HOSTNAME}" in
  coordinator)
    if [ ! -f ${MASTER_DATA_DIR}/whpgmne-1/postgresql.conf ]; then
        echo "Running gpinitsystem ..."
        # gpinitsystem logs a WARN about the trust-based pg_hba.conf notice
        # and exits 1 even on a fully successful init, so its exit code is
        # not a reliable success signal here -- same as the old cmd.sh,
        # which never checked it either. Tolerate it with `|| true`.
        ( source ${WHPG_HOME}/greenplum_path.sh && gpinitsystem -c /home/${WHPG_USER}/whpginitsystem_multinode -m 100 -a --mirror-mode=group -s standby -P 5432 -S ${STANDBY_DATA_DIR} ) || true
        echo "Running gpinitsystem ... done"
    else
        echo "Starting WarehousePG ..."
        # gpstart can report a WARNING/failure for a single component (e.g.
        # the standby coordinator's pg_ctl -w wait timing out over ssh under
        # emulation, even though it actually comes up) while the primary
        # cluster is otherwise healthy. Same class of unreliable exit code
        # as gpinitsystem above -- tolerate it with `|| true`.
        ( source ${WHPG_HOME}/greenplum_path.sh && gpstart -a -d ${MASTER_DATA_DIR}/whpgmne-1/ ) || true
        echo "Starting WarehousePG ... done"
    fi
    ;;
  gpfdist)
    source ${WHPG_HOME}/greenplum_path.sh
    echo "Starting gpfdist on port 30000, serving directory ${DATA_DIR}"
    nohup gpfdist -d ${DATA_DIR} -p 30000 -V > /home/${WHPG_USER}/gpfdist.log 2>&1 &
    disown
    ;;
  *)
    echo "Not the coordinator or gpfdist, nothing to start on ${HOSTNAME}"
    ;;
esac
