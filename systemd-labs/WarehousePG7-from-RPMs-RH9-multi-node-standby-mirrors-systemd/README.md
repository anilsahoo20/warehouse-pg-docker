# WarehousePG 7 — multi-node with standby coordinator + mirrors, RPMs, RHEL9, **systemd**

Same 5-container multi-node WarehousePG 7 cluster as
`../../WarehousePG7-from-RPMs-RH9-multi-node-standby-mirrors` (coordinator,
standby, seg1, seg2, gpfdist — with a standby coordinator and mirror
segments enabled), but every container boots **systemd as PID 1** and
manages WarehousePG (and sshd) as real units, instead of running `cmd.sh`
+ `tail -f /dev/null`.

See `../WarehousePG7-from-RPMs-RH9-multi-node-systemd/README.md` for the
full systemd-vs-tail-based comparison table and file breakdown — the
delta is identical, just with mirrors/standby added on top:

- `whpginitsystem_multinode7` declares `MIRROR_MACHINE_LIST_FILE`,
  `MIRROR_PORT_BASE`, `REPLICATION_PORT_BASE`,
  `MIRROR_REPLICATION_PORT_BASE`, and `MIRROR_DATA_DIRECTORY`.
- `warehousepg-setup.sh` additionally creates `/whpgdata/standby` and
  `/whpgdata/mirrors/whpgdata{1,2}`.
- `warehousepg-start.sh`'s coordinator branch runs `gpinitsystem` with
  `--mirror-mode=group -s standby -P 5432 -S ${STANDBY_DATA_DIR}`.
- Host ports: coordinator `6448:5432`, standby `6450:5432` (the plain
  multi-node systemd lab uses 6447/6449 — these are separate labs and can
  run side by side).

The ssh-bootstrap hardening in `warehousepg-setup.sh` (jitter + 40-attempt
retries + raised `MaxStartups`/`MaxSessions` baked into `sshd_config`) is
already the "standby-mirrors" hardened version — with more segments and
mirrors doing more ssh operations concurrently, this cluster stresses the
key-exchange bootstrap more than the plain multi-node lab, so the extra
margin matters here even more.

## Usage

```sh
make build
make run
make status
make psql-coordinator   # connect via host port 6448
make psql-standby       # connect via host port 6450
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
