# WarehousePG 7 — multi-node, 50 real segment hosts + standby + mirrors, RPMs, RHEL9, **systemd**

Derived from `../WarehousePG7-from-RPMs-RH9-multi-node-standby-mirrors-systemd`
(see its README for the systemd-vs-tail-based delta). Instead of 2 segment
hosts running 2 primaries each, this lab runs **50 segment containers**
(`seg1`..`seg50`), each hosting **1 primary + 1 mirror**:

- 52 containers total: `coordinator`, `standby`, `seg1`..`seg50`
- 50 primaries (port 6000) + 50 mirrors (port 7000, replication 8000/9000)
- `--mirror-mode=group`: the mirror of segN lives on seg(N+1) (seg50's on seg1)
- Host ports: coordinator `6470:5432`, standby `6471:5432` (different from
  the 4-node lab's 6448/6450, so both can coexist)

## What changed vs. the 4-node lab

| File | Change |
|---|---|
| `gen-cluster.sh` | **new** — generates `compose.yaml` + hostfiles for `NUM_SEGS` segments (default 50) |
| `compose.yaml` | generated; shared YAML anchor, one image built once (by `coordinator`) and reused by all services; segments limited to 1 CPU / 700 MB |
| `whpginitsystem_multinode7` | one `DATA_DIRECTORY` and one `MIRROR_DATA_DIRECTORY` per host |
| `warehousepg-setup.sh` | one primary + one mirror dir per host; **segments exchange ssh keys only with coordinator + standby** (a full mesh would be ~2,700 `ssh-copy-id` runs per user); wait budgets raised to 900s, jitter to 30s |
| `warehousepg.service` | `TimeoutStartSec=3600` for the slow 52-host bootstrap + `gpinitsystem` |
| `Makefile` | `access-seg` / `logs-seg` / `journal-seg` take `SEG=<n>` instead of per-segment targets |

## Resources

Needs a Docker Desktop VM of roughly **20+ GB RAM** (idle: ~300 MB per
segment container, 52 containers). Stop other labs first. For a quick
iteration use fewer segments:

```sh
NUM_SEGS=6 ./gen-cluster.sh && make build
```

(`NUM_SEGS` must be >= 2 for group mirroring.) Re-run `./gen-cluster.sh`
with no argument to go back to 50; the hostfiles are baked into the image,
so rebuild after changing the count.

## Usage

```sh
make build
make run                 # first boot takes a long time under amd64 emulation
make status
make psql-coordinator    # host port 6470
make psql-standby        # host port 6471
make access-seg SEG=17
make journal-coordinator
make stop
```

Verify the topology once up:

```sh
make psql-coordinator
# select role, count(*) from gp_segment_configuration where content >= 0 group by 1;   -- 50 p, 50 m
```
