# WarehousePG 6 — single node, RPMs, RHEL8, **systemd**

Same single-node WarehousePG 6 image as
`../WarehousePG6-from-RPMs-RH7-single-node-systemd`, but built on
`rockylinux:8` instead of CentOS 7. Like its RH7 sibling, the container
boots **systemd as PID 1** and manages WarehousePG (and sshd) as real
units, instead of running `cmd.sh` + `tail -f /dev/null`.

## What's different from the RH7 systemd variant

WarehousePG 6's tooling (`gpinitsystem`, `gpexpand`, etc.) is Python 2
based. RHEL8/Rocky8 only ships Python 2 through the `python27` module
stream, and that module only provides the bare interpreter + pip — not
the `python2-pytest`/`-lxml`/`-psutil`/`-pyyaml` RPMs that were
available on EL7 via EPEL. The `Dockerfile` enables the module
(`dnf module enable -y python27`) and installs those same modules via
`pip2` instead (see the comment above `RUN pip2 install ...`).

## What's different from the tail-based variant

| | tail-based variant | this (systemd) variant |
|---|---|---|
| PID 1 | `cmd.sh` then `tail -f /dev/null` | `/usr/sbin/init` (systemd) |
| sshd | backgrounded manually in `cmd.sh` | `sshd.service` |
| DB start/stop | `gpstart` in `cmd.sh`; no clean stop | `warehousepg.service` (`gpstart`/`gpinitsystem` + `gpstop` on stop) |
| runtime user | image ends `USER gpadmin` | stays root for PID 1; gpadmin via `User=` in the unit |
| `docker stop` | SIGTERM kills tail, DB not stopped cleanly | `SIGRTMIN+3` → systemd shutdown → `gpstop` |

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
make build
make run
make status
make psql        # connect via host port 6454
make journal     # follow the warehousepg.service journal (DB output)
make logs        # docker logs = systemd boot messages
make stop        # clean shutdown: docker stop -> systemd -> gpstop
```

## Caveat: Docker Desktop for Mac

This builds `linux/amd64` and runs under Docker Desktop (cgroup v2).
systemd-in-container can be finicky there. If it won't boot with
`cgroup: host` + the cgroup mount, fall back to `privileged: true` in
`compose.yaml`. The pattern is most reliable on Podman and native Linux
Docker — and on a real RHEL8 host it behaves better than under Docker
Desktop.
