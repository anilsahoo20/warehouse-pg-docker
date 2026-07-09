# WarehousePG 6 — multi-node with standby master + mirrors, RPMs, RHEL8, **systemd**

5-container multi-node WarehousePG 6 cluster (coordinator, standby, seg1,
seg2, gpfdist — with a standby master and mirror segments enabled),
adapted from `../WarehousePG7-from-RPMs-RH8-multi-node-standby-mirrors-systemd`.
Every container boots **systemd as PID 1** and manages WarehousePG (and
sshd) as real units, instead of running `cmd.sh` + `tail -f /dev/null`.

See `../WarehousePG7-from-RPMs-RH9-multi-node-systemd/README.md` for the
full systemd-vs-tail-based comparison table and file breakdown. What's
different here vs. the WarehousePG 7 multi-node-standby-mirrors labs:

- WarehousePG 6's `gpinitsystem` config uses `MASTER_HOSTNAME`/
  `MASTER_DIRECTORY`/`MASTER_PORT` (v6 terminology) instead of v7's
  `COORDINATOR_*` keys — the compose service is still named `coordinator`
  for consistency with the other multi-node labs, but its data directory
  is `/whpgdata/master` to match `gpinitsystem`'s own naming.
- WarehousePG 6 tooling (`gpinitsystem`/`gpexpand`) is Python 2 based.
  RHEL8/Rocky8 dropped the OS python2 package; EDB ships its own
  interpreter as `edb-python27` instead, pulled in automatically as a
  dependency of `warehouse-pg-6` — see the comment block in `Dockerfile`
  above the `alternatives --install` lines.
- `warehousepg-setup.sh` installs `psycopg2-binary`/`psutil` (prebuilt
  wheels) via that interpreter's `pip`, since `edb-python27` ships no dev
  headers to compile from source against.
- Host ports: coordinator `6455:5432`, standby `6456:5432` (separate from
  the WarehousePG 7 multi-node-standby-mirrors labs' ports — all of these
  can run side by side).

The ssh-bootstrap hardening in `warehousepg-setup.sh` (jitter + 40-attempt
retries + raised `MaxStartups`/`MaxSessions` baked into `sshd_config`) is
the same "standby-mirrors" hardened version proven in the WarehousePG 7
labs — necessary here too, since the same 5-container concurrent
ssh-copy-id storm happens regardless of WarehousePG version.

## Usage

```sh
make build
make run
make status
make psql-coordinator   # connect via host port 6455
make psql-standby       # connect via host port 6456
make journal-coordinator
make stop                # clean shutdown: docker stop -> systemd -> gpstop (coordinator)
```

## Caveats

Same as the plain multi-node systemd lab: Docker Desktop cgroup v2 can be
finicky with systemd-in-container (fall back to `privileged: true` if
needed), the cross-container ssh bootstrap is racy under emulation (retry
with `make restart` if `gpinitsystem` fails on first boot), and the
coordinator's `ExecStop` `gpstop` is best-effort since Compose doesn't
guarantee shutdown order across the 5 services.
