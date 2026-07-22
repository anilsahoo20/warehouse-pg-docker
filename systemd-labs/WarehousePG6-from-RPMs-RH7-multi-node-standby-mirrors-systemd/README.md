# WarehousePG 6 — multi-node with standby master + mirrors, RPMs, RHEL7, **systemd**

5-container multi-node WarehousePG 6 cluster (coordinator, standby, seg1,
seg2, gpfdist — with a standby master and mirror segments enabled),
adapted from `../WarehousePG6-from-RPMs-RH8-multi-node-standby-mirrors-systemd`
down to CentOS 7. Every container boots **systemd as PID 1** and manages
WarehousePG (and sshd) as real units, instead of running `cmd.sh` +
`tail -f /dev/null`.

See `../WarehousePG7-from-RPMs-RH9-multi-node-systemd/README.md` for the
full systemd-vs-tail-based comparison table and file breakdown. What's
different here vs. the WarehousePG 7 multi-node-standby-mirrors labs:

- WarehousePG 6's `gpinitsystem` config uses `MASTER_HOSTNAME`/
  `MASTER_DIRECTORY`/`MASTER_PORT` (v6 terminology) instead of v7's
  `COORDINATOR_*` keys — the compose service is still named `coordinator`
  for consistency with the other multi-node labs, but its data directory
  is `/whpgdata/master` to match `gpinitsystem`'s own naming.
- WarehousePG 6 tooling (`gpinitsystem`/`gpexpand`) is Python 2 based.
  CentOS7 ships python2 as the native OS package (already aliased to
  `/usr/bin/python`), so — unlike the RHEL8/RHEL9 variants of this lab,
  which need the `python27` module or EDB's own `edb-python27` — nothing
  special is needed here beyond listing `python2`/`python2-pytest`/
  `-lxml`/`-psutil`/`-pyyaml` (all real EPEL7 RPMs) in
  `rpm-packages-image-step.txt`.
- `warehousepg-setup.sh` still installs `psycopg2-binary` via `pip`
  (EPEL7 has no psycopg2 RPM), but `psutil` is already satisfied by the
  `python2-psutil` RPM, so that half of the loop is a no-op here.
- Host ports: coordinator `6459:5432`, standby `6460:5432` (separate from
  the RHEL8/RHEL9 variants of this lab and the WarehousePG 7 labs — all
  of these can run side by side).

The ssh-bootstrap hardening in `warehousepg-setup.sh` (jitter + 40-attempt
retries + raised `MaxStartups`/`MaxSessions` baked into `sshd_config`) is
the same "standby-mirrors" hardened version proven in the WarehousePG 7
labs — necessary here too, since the same 5-container concurrent
ssh-copy-id storm happens regardless of WarehousePG version or OS.

## Usage

```sh
make build
make run
make status
make psql-coordinator   # connect via host port 6459
make psql-standby       # connect via host port 6460
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
