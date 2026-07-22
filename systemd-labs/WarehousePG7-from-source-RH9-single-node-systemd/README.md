# WarehousePG 7 — single node, built from source, RHEL9, **systemd**

Same single-node WarehousePG 7 image as
`../../WarehousePG7-from-source-RH9-single-node` (built from a `git clone` +
`configure` + `make`, not from RPMs), but the container boots
**systemd as PID 1** and manages WarehousePG (and sshd) as real units,
instead of running `cmd.sh` + `tail -f /dev/null`.

## What's different from the tail-based variant

| | tail-based variant | this (systemd) variant |
|---|---|---|
| PID 1 | `cmd.sh` then `tail -f /dev/null` | `/usr/sbin/init` (systemd) |
| sshd | backgrounded manually in `cmd.sh` | `sshd.service` |
| DB start/stop | `gpstart` in `cmd.sh`; no clean stop | `warehousepg.service` (`gpstart`/`gpinitsystem` + `gpstop` on stop) |
| runtime user | image ends `USER gpadmin` | stays root for PID 1; gpadmin via `User=` in the unit |
| `docker stop` | SIGTERM kills tail, DB not stopped cleanly | `SIGRTMIN+3` → systemd shutdown → `gpstop` |

The build stage is unchanged from the tail-based lab: it still clones
the WarehousePG source, runs `dnf groupinstall "Development Tools"`,
`./configure --enable-orca --enable-pxf`, `make`, and `make install` as
`gpadmin`. Only the image stage (the runtime image, without the build
toolchain/sources) gets the systemd delta.

### Files
- `warehousepg.service` — oneshot unit: `ExecStartPre` runs the prep
  script, `ExecStart` does `gpinitsystem` (first boot) or `gpstart`
  (later boots), `ExecStartPost` applies the dev trust line, `ExecStop`
  runs `gpstop`.
- `warehousepg-setup.sh` — gpadmin ssh-to-localhost keys + bundled-Python
  modules (the parts of the old `cmd.sh` that are still needed).
- `warehousepg-poststart.sh` — dev-only `pg_hba.conf` trust line + reload.
- `compose.yaml` — adds `cgroup: host`, the `/sys/fs/cgroup` mount,
  `tmpfs` for `/run` and `/tmp`, and `stop_signal: SIGRTMIN+3`.

## Note: `gpinitsystem -a` and `|| true`

`gpinitsystem` logs a WARN about trust-based `pg_hba.conf` and exits
non-zero even on a fully successful initialization. The unit's
`ExecStart` tolerates that with `|| true` on the `gpinitsystem`
invocation — without it, `Type=oneshot` treats the non-zero exit as a
unit failure, `ExecStartPost` never runs, and the coordinator never
starts even though the segments do.

## Usage

```sh
make build
make run
make status
make psql        # connect via host port 6444
make journal     # follow the warehousepg.service journal (DB output)
make logs        # docker logs = systemd boot messages
make stop        # clean shutdown: docker stop -> systemd -> gpstop
```

## Caveat: build time

This lab compiles WarehousePG from source instead of installing RPMs.
`make build` runs a full `git clone` + `configure` + `make` of the
database, which is CPU- and I/O-heavy. Under emulation (e.g. `linux/amd64`
on an Apple Silicon Mac via Rosetta/QEMU), this can take **30-60+
minutes** — this is expected, not a hang. Let it run.

## Caveat: Docker Desktop for Mac

This builds `linux/amd64` and runs under Docker Desktop (cgroup v2).
systemd-in-container can be finicky there. If it won't boot with
`cgroup: host` + the cgroup mount, fall back to `privileged: true` in
`compose.yaml`. The pattern is most reliable on Podman and native Linux
Docker — and on a real RHEL9 host it behaves better than under Docker
Desktop.
