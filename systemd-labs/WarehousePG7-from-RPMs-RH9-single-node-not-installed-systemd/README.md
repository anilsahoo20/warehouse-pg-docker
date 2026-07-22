# WarehousePG 7 — single node, RPMs, RHEL9, not installed, **systemd**

Same intentionally-not-installed lab as
`../../WarehousePG7-from-RPMs-RH9-single-node-not-installed`, but the
container boots **systemd as PID 1** (with `sshd.service` enabled)
instead of just running `tail -f /dev/null`.

## What this lab is for

WarehousePG is **not** installed or configured in this image. The RPMs
(`warehouse-pg-7`, `warehouse-pg-clients`, `whpg-backup`) are downloaded
during the build into `/root/rpm-downloads`, but never `dnf install`ed.
There is no database to start, and no `warehousepg.service` — this lab
exists so a trainee can practice the manual install + `gpinitsystem`
steps themselves, on a realistic systemd-managed RHEL9-like OS.

Compared to `../../WarehousePG7-from-RPMs-RH9-single-node-not-installed`,
the delta here is deliberately minimal:

| | tail-based variant | this (systemd) variant |
|---|---|---|
| PID 1 | `tail -f /dev/null` (no `cmd.sh`, it's not even wired to CMD) | `/usr/sbin/init` (systemd) |
| sshd | not running | `sshd.service` |
| WarehousePG | not installed, not started, by design | not installed, not started, by design |
| runtime user | image ends `USER gpadmin` | stays root for PID 1 |
| units | n/a | only `sshd.service` enabled — no `warehousepg.service` |

There is no `warehousepg-setup.sh`, no `warehousepg-poststart.sh`, and
no `warehousepg.service` unit in this lab. There is deliberately nothing
to auto-start.

## Usage

```sh
make build
make run
make status
make access      # or: docker compose exec sne bash
```

Once inside the container as root:

```sh
su - gpadmin
ls /root/rpm-downloads          # pre-downloaded RPMs, not yet installed
# as root, or via sudo from gpadmin:
sudo dnf install -y /root/rpm-downloads/*.rpm
# then, as gpadmin, initialize the cluster by hand, e.g.:
source /usr/local/greenplum-db/greenplum_path.sh
gpinitsystem -c /home/gpadmin/whpginitsystem_singlenode
```

`hostfile_whpginitsystem`, `whpginitsystem_singlenode`, and
`warehousepg_init.sh` are pre-staged in `/home/gpadmin`, same as the
non-systemd variant, to support this manual walk-through.

Other targets:

```sh
make journal     # follow the full systemd journal (there's no single
                 # service to filter to -- sshd is the only unit that runs)
make logs        # docker logs = systemd boot messages
make stop        # clean shutdown via SIGRTMIN+3
```

No database verification applies to this lab by design — success here
is systemd reaching a running state with `sshd.service` active, and
`gpadmin` existing so the trainee can start their manual install.

## Caveat: Docker Desktop for Mac

This builds `linux/amd64` and runs under Docker Desktop (cgroup v2).
systemd-in-container can be finicky there. If it won't boot with
`cgroup: host` + the cgroup mount, fall back to `privileged: true` in
`compose.yaml`. The pattern is most reliable on Podman and native Linux
Docker — and on a real RHEL9 host it behaves better than under Docker
Desktop.
