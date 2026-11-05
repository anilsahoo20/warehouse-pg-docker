BUILD_VERSION="0.1"
BUILD_IMAGE_TITLE="WarehousePG 7 Database"
BUILD_IMAGE_DESCRIPTION="WarehousePG 7.x Database image"


TCP_PORT="6470"


include ../../token.mk


CURRENT_UID := $(shell id -u)

# keep in sync with ./gen-cluster.sh (default 50)
NUM_SEGS ?= $(shell grep -c . hostfile_segments_whpginitsystem7)
SEGS := $(shell seq 1 $(NUM_SEGS))
SEG ?= 1


all:
	@echo ""
	@echo "WarehousePG 7.x multi-node setup (coordinator + standby + $(NUM_SEGS) segment hosts, mirrors), built from RPMs, systemd"
	@echo ""
	@echo "build:    (Re)build the image"
	@echo "run:      Start the image"
	@echo "status:   Show Docker compose status"
	@echo "psql:     Connect to the WarehousePG Database in the image"
	@echo "access:   Get a shell in the image"
	@echo "logs:     Show the Docker log for the image (systemd boot)"
	@echo "journal:  Follow the warehousepg.service journal (DB start/stop)"
	@echo "stop:     Stop the image (preserves state)"
	@echo "start:    Start a previously stopped image"
	@echo "restart:  Restart the image"
	@echo "clean:    Remove all artifacts"

build:
	@# Docker may create the data directories already - as root
	mkdir -p $(shell pwd)/data
	@for i in coordinator standby $(addprefix seg,$(SEGS)); do mkdir -p data/$$i data/$$i/data; done
	DOCKER_BUILDKIT=1 docker compose up --build --no-start --remove-orphans
	docker image prune -f
	docker buildx prune -f

run:	checksudo
	@mkdir -p data
	@sudo chown `id -un`:`id -gn` data data/* ; true
	@for i in coordinator standby $(addprefix seg,$(SEGS)); do mkdir -p data/$$i data/$$i/data; done
	@# Docker Desktop's VirtioFS bind-mount cache can lag behind
	@# directories created just above -- docker compose then tries to
	@# mount all containers at once and one of them sees a stale (pre-
	@# mkdir) view, failing with "no such file or directory". Warm the
	@# cache with a throwaway container walk before compose starts.
	@docker run --rm -v "$(shell pwd)/data:/mnt/data" alpine find /mnt/data >/dev/null 2>&1 || true
	DOCKER_BUILDKIT=1 docker compose up --detach || \
		(echo "Retrying once (Docker Desktop mount cache was still catching up)..." && sleep 2 && DOCKER_BUILDKIT=1 docker compose up --detach)

status:
	docker compose ps

psql:
	@echo ""
	@echo "Use:"
	@echo ""
	@printf "make psql-coordinator\t\tConnect psql to coordinator host"
	@printf "make psql-standby\t\tConnect psql to standby host"
	@echo ""

psql-coordinator:
	psql -h 127.0.0.1 -p 6470 -U gpadmin postgres

psql-standby:
	psql -h 127.0.0.1 -p 6471 -U gpadmin postgres

stop:
	docker compose stop -t 5
	docker compose ps -a

start:
	docker compose start
	docker compose ps

restart:
	docker compose restart
	docker compose ps

clean:	stop checksudo
	docker compose rm -f
	@#sudo rm -rf data
	@if [ -d data ] && [ $$(find data -mindepth 1 -not -uid $(CURRENT_UID) -print -quit | wc -l) -gt 0 ]; then \
		sudo rm -rf data; \
	elif [ -d data ]; then \
		rm -rf data; \
	fi

cleanall:	clean
	docker image prune --all --force
	docker network prune --force
	docker system prune --all --force

logs:
	@echo ""
	@echo "Use:"
	@echo ""
	@printf "make logs-coordinator\t\tShow logs from coordinator host\n"
	@printf "make logs-standby\t\tShow logs from standby host\n"
	@printf "make logs-seg SEG=17\t\tShow logs from segment host 17\n"
	@echo ""

logs-coordinator:
	docker compose logs -f coordinator

logs-standby:
	docker compose logs -f standby

logs-seg:
	docker compose logs -f seg$(SEG)

journal:
	@echo ""
	@echo "Use:"
	@echo ""
	@printf "make journal-coordinator\tFollow the warehousepg.service journal on coordinator\n"
	@printf "make journal-standby\t\tFollow the warehousepg.service journal on standby\n"
	@printf "make journal-seg SEG=17\tFollow the warehousepg.service journal on segment host 17\n"
	@echo ""

journal-coordinator:
	docker compose exec coordinator journalctl -u warehousepg.service -f

journal-standby:
	docker compose exec standby journalctl -u warehousepg.service -f

journal-seg:
	docker compose exec seg$(SEG) journalctl -u warehousepg.service -f

access:
	@echo ""
	@echo "Use:"
	@echo ""
	@printf "make access-coordinator\t\tConnect to coordinator host\n"
	@printf "make access-standby\t\tConnect to standby host\n"
	@printf "make access-seg SEG=17\t\tConnect to segment host 17\n"
	@echo ""

access-coordinator:
	@echo "Don't forget to run:"
	@echo "  source /usr/local/greenplum-db/greenplum_path.sh"
	@echo "psql command is:"
	@echo "  psql whpgtest"
	@docker compose exec coordinator /bin/bash

access-standby:
	@echo "Don't forget to run:"
	@echo "  source /usr/local/greenplum-db/greenplum_path.sh"
	@echo "psql command is:"
	@echo "  psql whpgtest"
	@docker compose exec standby /bin/bash

access-seg:
	@echo ""
	@echo "Segment databases running on ports: "`docker compose exec seg$(SEG) /home/gpadmin/list-seg-ports.sh`
	@echo ""
	@echo "Don't forget to run:"
	@echo "  source /usr/local/greenplum-db/greenplum_path.sh"
	@echo "psql command is (plus port):"
	@echo "  PGOPTIONS='-c gp_session_role=utility' psql -d whpgtest -p "
	@docker compose exec seg$(SEG) /bin/bash

checksudo::
	@if ! sudo -n true 2>/dev/null; then \
		echo "Note: Entering a sudo password might be required ..."; \
		echo "      The data/ directory contains files owned by another user"; \
		echo "      This was caused by the Docker lab changing ownership of files"; \
		echo ""; \
	fi

checklabsrunning:
	../../labs-are-running.sh

.PHONY:	all build run start restart logs stop clean cleanall status checksudo checklabsrunning
.PHONY: psql psql-coordinator psql-standby
.PHONY: access access-coordinator access-standby access-seg
.PHONY: logs logs-coordinator logs-standby logs-seg
.PHONY: journal journal-coordinator journal-standby journal-seg
