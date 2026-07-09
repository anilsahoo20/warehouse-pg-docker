# WarehousePG 6 — single node, built from source, RHEL7, **systemd**

Same single-node WarehousePG 6 image as
`../../WarehousePG6-from-source-RH7-single-node` (built from source: git
clone + `configure`/`make`/`make install`, not RPMs), but the container
boots **systemd as PID 1** and manages WarehousePG (and sshd) as real
units, instead of running `cmd.sh` + `tail -f /dev/null`.

## Heads up: `make build` is slow

This lab compiles WarehousePG from source (devtoolset-7, `configure`,
`make -j$(nproc)`). Under Docker Desktop for Mac / Rosetta emulation
(`linux/amd64` on Apple Silicon) this routinely takes **30-60+ minutes**.
That is expected — it is not a hang. The RPM-based systemd lab
(`../WarehousePG6-from-RPMs-RH7-single-node-systemd`) is much faster to
build if you just need a running WarehousePG 6 with systemd and don't
care about building from source.

## What's different from the tail-based variant

| | tail-based variant | this (systemd) variant |
|---|---|---|
| PID 1 | `cmd.sh` then `tail -f /dev/null` | `/usr/sbin/init` (systemd) |
| sshd | backgrounded manually in `cmd.sh` | `sshd.service` |
| DB start/stop | `gpstart` in `cmd.sh`; no clean stop | `warehousepg.service` (`gpstart`/`gpinitsystem` + `gpstop` on stop) |
| runtime user | image ends `USER gpadmin` | stays root for PID 1; gpadmin via `User=` in the unit |
| `docker stop` | SIGTERM kills tail, DB not stopped cleanly | `SIGRTMIN+3` → systemd shutdown → `gpstop` |

The build stage (git clone, `configure`, `make`, `make install`, and the
build-time `pip install psycopg2`/`psutil`) is unchanged from the
tail-based variant.

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

## Usage

```sh
make build       # slow: compiles WarehousePG from source, 30-60+ min under emulation
make run
make status
make psql        # connect via host port 6443
make journal     # follow the warehousepg.service journal (DB output)
make logs        # docker logs = systemd boot messages
make stop        # clean shutdown: docker stop -> systemd -> gpstop
```

## Caveat: Docker Desktop for Mac

This builds `linux/amd64` and runs under Docker Desktop (cgroup v2).
systemd-in-container can be finicky there. If it won't boot with
`cgroup: host` + the cgroup mount, fall back to `privileged: true` in
`compose.yaml`. The pattern is most reliable on Podman and native Linux
Docker — and on a real RHEL7 host it behaves better than under Docker
Desktop.
