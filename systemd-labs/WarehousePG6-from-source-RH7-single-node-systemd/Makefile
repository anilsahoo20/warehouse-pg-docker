BUILD_VERSION="0.1"
BUILD_IMAGE_TITLE="WarehousePG 6 Database"
BUILD_IMAGE_DESCRIPTION="WarehousePG 6.x Database image"


IMAGE_NAME="sne"
HOST_NAME="whpgdb-primary"
TCP_PORT="6443"


CURRENT_UID := $(shell id -u)


all:
	@echo ""
	@echo "WarehousePG 6.x, built from source, systemd"
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
	mkdir -p $(shell pwd)/data
	DOCKER_BUILDKIT=1 docker compose up --build --no-start --remove-orphans
	docker image prune -f
	docker buildx prune -f

run:
	mkdir -p $(shell pwd)/data
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
	psql -h 127.0.0.1 -p $(TCP_PORT) -U gpadmin postgres

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
	docker compose logs -f $(IMAGE_NAME)

journal:
	docker compose exec $(IMAGE_NAME) journalctl -u warehousepg.service -f

access:
	@echo "Don't forget to run:"
	@echo "  source /usr/local/greenplum-db/greenplum_path.sh"
	@echo "psql command is:"
	@echo "  psql whpgtest"
	@docker compose exec $(IMAGE_NAME) /bin/bash

checksudo:
	@if ! sudo -n true 2>/dev/null; then \
		echo "Note: Entering a sudo password might be required ..."; \
		echo "      The data/ directory contains files owned by another user"; \
		echo "      This was caused by the Docker lab changing ownership of files"; \
		echo ""; \
	fi

checklabsrunning:
	../../labs-are-running.sh

.PHONY:	all build run start restart psql access logs journal stop clean cleanall status checksudo checklabsrunning
