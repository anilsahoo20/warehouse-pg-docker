# WarehousePG Docker Setup — systemd labs

Same labs as the parent directory, but every container boots **systemd
as PID 1** (`/usr/sbin/init`) and manages WarehousePG (and sshd) as real
systemd units, instead of running `cmd.sh` + `tail -f /dev/null`. This is
closer to how these OSes actually behave on a real host — useful for
practicing systemd/journald workflows, or for labs that specifically
need `docker stop` to trigger a clean `gpstop` via a unit's `ExecStop`.

Each lab's own `README.md` documents its specific systemd-vs-tail-based
delta; `../WarehousePG7-from-RPMs-RH9-multi-node-systemd/README.md` has
the fullest version of that comparison table.

## Table of Contents

| Lab | WarehousePG | OS | Topology |
|---|---|---|---|
| `WarehousePG6-from-RPMs-RH7-single-node-systemd` | v6 | CentOS 7 | single node |
| `WarehousePG6-from-RPMs-RH8-single-node-systemd` | v6 | Rocky Linux 8 | single node |
| `WarehousePG6-from-RPMs-RH9-single-node-systemd` | v6 | Rocky Linux 9 | single node |
| `WarehousePG6-from-source-RH7-single-node-systemd` | v6 | CentOS 7 | single node, built from source |
| `WarehousePG6-from-RPMs-RH7-multi-node-standby-mirrors-systemd` | v6 | CentOS 7 | multi-node, standby master + mirrors |
| `WarehousePG6-from-RPMs-RH8-multi-node-standby-mirrors-systemd` | v6 | Rocky Linux 8 | multi-node, standby master + mirrors |
| `WarehousePG6-from-RPMs-RH9-multi-node-standby-mirrors-systemd` | v6 | Rocky Linux 9 | multi-node, standby master + mirrors |
| `WarehousePG7-from-RPMs-RH8-single-node-systemd` | v7 | Rocky Linux 8 | single node |
| `WarehousePG7-from-RPMs-RH9-single-node-systemd` | v7 | Rocky Linux 9 | single node |
| `WarehousePG7-from-source-RH9-single-node-systemd` | v7 | Rocky Linux 9 | single node, built from source |
| `WarehousePG7-from-RPMs-RH9-single-node-not-installed-systemd` | v7 | Rocky Linux 9 | single node, RPMs downloaded but not installed (training) |
| `WarehousePG7-from-RPMs-RH9-multi-node-systemd` | v7 | Rocky Linux 9 | multi-node (no standby, no mirrors) |
| `WarehousePG7-from-RPMs-RH8-multi-node-standby-mirrors-systemd` | v7 | Rocky Linux 8 | multi-node, standby coordinator + mirrors |
| `WarehousePG7-from-RPMs-RH9-multi-node-standby-mirrors-systemd` | v7 | Rocky Linux 9 | multi-node, standby coordinator + mirrors |

WarehousePG 6 uses `MASTER_HOSTNAME`/`MASTER_DIRECTORY`/`MASTER_PORT`
(v6 `gpinitsystem` terminology) and needs Python 2 (via the OS's native
package on CentOS7, the `python27` module on Rocky8, or EDB's own
`edb-python27` on Rocky9, which dropped python2 entirely) — see each
lab's `README.md` for the exact mechanism used on that OS. WarehousePG 7
uses `COORDINATOR_*` naming and Python 3.11.

## Host ports

Every lab maps three container ports to a unique host port, incrementing
across the whole set (multi-node labs map `5432` for both the coordinator
*and* the standby, since both need to be reachable):

| Container port | Purpose | Host range |
|---|---|---|
| `5432` | PostgreSQL/WarehousePG | `6441`–`6460` |
| `8080` | (reserved) | `18080`–`18093` |
| `7233` | (reserved) | `17233`–`17246` |

(The non-systemd labs in the parent directory use `5432`→`6432`-`6440`
and one `8081`→`8080` mapping — no overlap with the systemd labs' ranges.)

Run `make -n build` in any lab to see its exact port mapping, or check
that lab's `compose.yaml`.

## Usage

Each lab follows the same `make` targets as its non-systemd counterpart,
plus `make journal` (follow the `warehousepg.service` journal — the real
place to watch startup/shutdown output, since `docker logs` only shows
what journald forwards to the console):

```sh
cd WarehousePG7-from-RPMs-RH9-single-node-systemd
make build
make run
make status
make psql        # or make psql-coordinator / make psql-standby on multi-node labs
make journal
make stop
make clean
```

See `../Makefile` for `build-everything`/`run-everything`/
`stop-everything`/`start-everything`/`restart-everything`/
`status-everything`/`clean-everything` targets that operate on every lab
in the repo (normal and systemd) from the repo root.

## Caveat: Docker Desktop for Mac

All of these build `linux/amd64` and run under Docker Desktop (cgroup
v2). systemd-in-container can be finicky there — if a lab won't boot
with `cgroup: host` + the cgroup mount, fall back to `privileged: true`
in that lab's `compose.yaml`. The pattern is most reliable on Podman and
native Linux Docker, and on a real matching-OS host it behaves better
than under Docker Desktop.
