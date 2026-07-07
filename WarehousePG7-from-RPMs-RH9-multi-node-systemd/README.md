# WarehousePG 7 — multi-node, RPMs, RHEL9, **systemd**

Same 5-container multi-node WarehousePG 7 cluster as
`../WarehousePG7-from-RPMs-RH9-multi-node` (coordinator, standby,
seg1, seg2, gpfdist), but every container boots **systemd as PID 1** and
manages WarehousePG (and sshd) as real units, instead of running `cmd.sh`
+ `tail -f /dev/null`.

## What's different from the tail-based variant

| | tail-based variant | this (systemd) variant |
|---|---|---|
| PID 1 | `cmd.sh` then `tail -f /dev/null` | `/usr/sbin/init` (systemd) |
| sshd | backgrounded manually, flags passed on the command line | `sshd.service`; `PermitRootLogin`/`MaxStartups`/`MaxSessions` baked into `/etc/ssh/sshd_config` at build time |
| DB start/stop | role-branching logic in `cmd.sh`; no clean stop | `warehousepg.service` (`ExecStartPre` = ssh key exchange, `ExecStart` = role-branching `warehousepg-start.sh`, `ExecStop` = `gpstop` on the coordinator) |
| runtime user | image ends `USER gpadmin` | stays root for PID 1; gpadmin via `User=` in the unit |
| `docker stop` | SIGTERM kills tail, DB not stopped cleanly | `SIGRTMIN+3` → systemd shutdown → coordinator's `ExecStop` runs `gpstop` (best-effort: only works if the other hosts are still reachable) |

All 5 containers share the same image and branch on `hostname`, exactly
like the tail-based lab's `cmd.sh` did.

### Files
- `warehousepg.service` — oneshot unit, same shape on every host:
  `ExecStartPre` = `warehousepg-setup.sh` (ssh key exchange across all 5
  hosts), `ExecStart` = `warehousepg-start.sh` (role branch: `gpinitsystem`/
  `gpstart` on the coordinator, a backgrounded `gpfdist` daemon on the
  gpfdist host, no-op on standby/seg1/seg2), `ExecStartPost` =
  `warehousepg-poststart.sh` (coordinator-only dev trust line),
  `ExecStop` = coordinator-only `gpstop`.
- `warehousepg-setup.sh` — the ssh-key-exchange half of the old `cmd.sh`
  (gpadmin + root keypairs, push keys to `hostfile_ssh_whpginitsystem`
  hosts, wait for convergence). Includes the same jitter + generous-retry
  hardening as the standby-mirrors lab's `cmd.sh`, because under systemd
  all 5 containers reach this step at roughly the same time — the same
  concurrent ssh-copy-id storm that hardening was built for.
- `warehousepg-start.sh` — the role-branching half of the old `cmd.sh`
  (gpinitsystem/gpstart/gpfdist/no-op).
- `warehousepg-poststart.sh` — dev-only `pg_hba.conf` trust line + reload,
  coordinator-only.

## Usage

```sh
make build
make run
make status
make psql-coordinator   # connect via host port 6441
make psql-standby       # connect via host port 6442
make journal-coordinator   # follow the warehousepg.service journal on a given host
make logs-coordinator       # docker logs = systemd boot messages
make stop                   # clean shutdown: docker stop -> systemd -> gpstop (coordinator)
```

## Caveats

- Docker Desktop for Mac: builds `linux/amd64`, cgroup v2 can be finicky
  with systemd-in-container. Fall back to `privileged: true` per service
  in `compose.yaml` if `cgroup: host` + the cgroup mount won't boot.
- The cross-container ssh bootstrap is inherently racy under emulation —
  see the hardening notes in `warehousepg-setup.sh`. If `gpinitsystem`
  fails on first boot with ssh errors, `make restart` and let the
  bootstrap retry; the data directories are idempotent (bind-mounted under
  `data/<host>/data`).
- `ExecStop`'s `gpstop` on the coordinator is best-effort: Docker Compose
  does not guarantee stop order across services, so if the segment
  containers are already gone by the time the coordinator's `ExecStop`
  runs, the `gpstop` over ssh will simply fail silently (`|| true`) — this
  is still strictly better than the tail-based lab, which never attempted
  a graceful shutdown at all.
