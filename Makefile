
include token.mk


all:
	@echo "Available targets:"
	@echo ""
	@printf "\tbuild-everything\t\tBuilds all images (makes them available for a testing)\n"
	@printf "\trun-everything\t\t\tStarts all images\n"
	@printf "\tstatus-everything\t\tShows Docker Compose status for all labs\n"
	@printf "\tstop-everything\t\t\tStops all images (preserves state)\n"
	@printf "\tstart-everything\t\tStarts all previously stopped images\n"
	@printf "\trestart-everything\t\tRestarts all images\n"
	@printf "\tclean-everything\t\tRemoves all artifacts for all labs\n"
	@printf "\tclean-docker\t\t\tRemove all Docker artifacts\n"
	@echo ""

docker-running:
	@docker info > /dev/null 2>&1 && echo "Docker is running!" > /dev/null || echo "Docker is not running!"
	@docker info > /dev/null 2>&1 && echo "Docker is running!" > /dev/null || exit 1

build-everything:	docker-running
	cd WarehousePG6-from-source-RH7-single-node/ && make MAKELEVEL=0 build
	cd WarehousePG7-from-source-RH9-single-node/ && make MAKELEVEL=0 build
	cd WarehousePG6-from-RPMs-RH7-single-node/ && make MAKELEVEL=0 build
	cd WarehousePG7-from-RPMs-RH9-single-node/ && make MAKELEVEL=0 build
	cd WarehousePG7-from-RPMs-RH9-multi-node/ && make MAKELEVEL=0 build
	cd WarehousePG7-from-RPMs-RH9-multi-node-standby-mirrors/ && make MAKELEVEL=0 build
	cd WarehousePG7-from-RPMs-RH9-single-node-not-installed/ && make MAKELEVEL=0 build
	cd systemd-labs/WarehousePG6-from-RPMs-RH7-single-node-systemd/ && make MAKELEVEL=0 build
	cd systemd-labs/WarehousePG6-from-RPMs-RH8-single-node-systemd/ && make MAKELEVEL=0 build
	cd systemd-labs/WarehousePG6-from-RPMs-RH9-single-node-systemd/ && make MAKELEVEL=0 build
	cd systemd-labs/WarehousePG6-from-source-RH7-single-node-systemd/ && make MAKELEVEL=0 build
	cd systemd-labs/WarehousePG6-from-RPMs-RH7-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 build
	cd systemd-labs/WarehousePG6-from-RPMs-RH8-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 build
	cd systemd-labs/WarehousePG6-from-RPMs-RH9-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 build
	cd systemd-labs/WarehousePG7-from-RPMs-RH8-single-node-systemd/ && make MAKELEVEL=0 build
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-single-node-systemd/ && make MAKELEVEL=0 build
	cd systemd-labs/WarehousePG7-from-source-RH9-single-node-systemd/ && make MAKELEVEL=0 build
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-single-node-not-installed-systemd/ && make MAKELEVEL=0 build
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-multi-node-systemd/ && make MAKELEVEL=0 build
	cd systemd-labs/WarehousePG7-from-RPMs-RH8-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 build
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 build

run-everything:	docker-running
	cd WarehousePG6-from-source-RH7-single-node/ && make MAKELEVEL=0 run
	cd WarehousePG7-from-source-RH9-single-node/ && make MAKELEVEL=0 run
	cd WarehousePG6-from-RPMs-RH7-single-node/ && make MAKELEVEL=0 run
	cd WarehousePG7-from-RPMs-RH9-single-node/ && make MAKELEVEL=0 run
	cd WarehousePG7-from-RPMs-RH9-multi-node/ && make MAKELEVEL=0 run
	cd WarehousePG7-from-RPMs-RH9-multi-node-standby-mirrors/ && make MAKELEVEL=0 run
	cd WarehousePG7-from-RPMs-RH9-single-node-not-installed/ && make MAKELEVEL=0 run
	cd systemd-labs/WarehousePG6-from-RPMs-RH7-single-node-systemd/ && make MAKELEVEL=0 run
	cd systemd-labs/WarehousePG6-from-RPMs-RH8-single-node-systemd/ && make MAKELEVEL=0 run
	cd systemd-labs/WarehousePG6-from-RPMs-RH9-single-node-systemd/ && make MAKELEVEL=0 run
	cd systemd-labs/WarehousePG6-from-source-RH7-single-node-systemd/ && make MAKELEVEL=0 run
	cd systemd-labs/WarehousePG6-from-RPMs-RH7-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 run
	cd systemd-labs/WarehousePG6-from-RPMs-RH8-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 run
	cd systemd-labs/WarehousePG6-from-RPMs-RH9-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 run
	cd systemd-labs/WarehousePG7-from-RPMs-RH8-single-node-systemd/ && make MAKELEVEL=0 run
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-single-node-systemd/ && make MAKELEVEL=0 run
	cd systemd-labs/WarehousePG7-from-source-RH9-single-node-systemd/ && make MAKELEVEL=0 run
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-single-node-not-installed-systemd/ && make MAKELEVEL=0 run
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-multi-node-systemd/ && make MAKELEVEL=0 run
	cd systemd-labs/WarehousePG7-from-RPMs-RH8-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 run
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 run

status-everything:	docker-running
	cd WarehousePG6-from-source-RH7-single-node/ && make MAKELEVEL=0 status
	cd WarehousePG7-from-source-RH9-single-node/ && make MAKELEVEL=0 status
	cd WarehousePG6-from-RPMs-RH7-single-node/ && make MAKELEVEL=0 status
	cd WarehousePG7-from-RPMs-RH9-single-node/ && make MAKELEVEL=0 status
	cd WarehousePG7-from-RPMs-RH9-multi-node/ && make MAKELEVEL=0 status
	cd WarehousePG7-from-RPMs-RH9-multi-node-standby-mirrors/ && make MAKELEVEL=0 status
	cd WarehousePG7-from-RPMs-RH9-single-node-not-installed/ && make MAKELEVEL=0 status
	cd systemd-labs/WarehousePG6-from-RPMs-RH7-single-node-systemd/ && make MAKELEVEL=0 status
	cd systemd-labs/WarehousePG6-from-RPMs-RH8-single-node-systemd/ && make MAKELEVEL=0 status
	cd systemd-labs/WarehousePG6-from-RPMs-RH9-single-node-systemd/ && make MAKELEVEL=0 status
	cd systemd-labs/WarehousePG6-from-source-RH7-single-node-systemd/ && make MAKELEVEL=0 status
	cd systemd-labs/WarehousePG6-from-RPMs-RH7-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 status
	cd systemd-labs/WarehousePG6-from-RPMs-RH8-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 status
	cd systemd-labs/WarehousePG6-from-RPMs-RH9-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 status
	cd systemd-labs/WarehousePG7-from-RPMs-RH8-single-node-systemd/ && make MAKELEVEL=0 status
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-single-node-systemd/ && make MAKELEVEL=0 status
	cd systemd-labs/WarehousePG7-from-source-RH9-single-node-systemd/ && make MAKELEVEL=0 status
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-single-node-not-installed-systemd/ && make MAKELEVEL=0 status
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-multi-node-systemd/ && make MAKELEVEL=0 status
	cd systemd-labs/WarehousePG7-from-RPMs-RH8-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 status
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 status

stop-everything:	docker-running
	cd WarehousePG6-from-source-RH7-single-node/ && make MAKELEVEL=0 stop
	cd WarehousePG7-from-source-RH9-single-node/ && make MAKELEVEL=0 stop
	cd WarehousePG6-from-RPMs-RH7-single-node/ && make MAKELEVEL=0 stop
	cd WarehousePG7-from-RPMs-RH9-single-node/ && make MAKELEVEL=0 stop
	cd WarehousePG7-from-RPMs-RH9-multi-node/ && make MAKELEVEL=0 stop
	cd WarehousePG7-from-RPMs-RH9-multi-node-standby-mirrors/ && make MAKELEVEL=0 stop
	cd WarehousePG7-from-RPMs-RH9-single-node-not-installed/ && make MAKELEVEL=0 stop
	cd systemd-labs/WarehousePG6-from-RPMs-RH7-single-node-systemd/ && make MAKELEVEL=0 stop
	cd systemd-labs/WarehousePG6-from-RPMs-RH8-single-node-systemd/ && make MAKELEVEL=0 stop
	cd systemd-labs/WarehousePG6-from-RPMs-RH9-single-node-systemd/ && make MAKELEVEL=0 stop
	cd systemd-labs/WarehousePG6-from-source-RH7-single-node-systemd/ && make MAKELEVEL=0 stop
	cd systemd-labs/WarehousePG6-from-RPMs-RH7-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 stop
	cd systemd-labs/WarehousePG6-from-RPMs-RH8-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 stop
	cd systemd-labs/WarehousePG6-from-RPMs-RH9-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 stop
	cd systemd-labs/WarehousePG7-from-RPMs-RH8-single-node-systemd/ && make MAKELEVEL=0 stop
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-single-node-systemd/ && make MAKELEVEL=0 stop
	cd systemd-labs/WarehousePG7-from-source-RH9-single-node-systemd/ && make MAKELEVEL=0 stop
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-single-node-not-installed-systemd/ && make MAKELEVEL=0 stop
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-multi-node-systemd/ && make MAKELEVEL=0 stop
	cd systemd-labs/WarehousePG7-from-RPMs-RH8-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 stop
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 stop

start-everything:	docker-running
	cd WarehousePG6-from-source-RH7-single-node/ && make MAKELEVEL=0 start
	cd WarehousePG7-from-source-RH9-single-node/ && make MAKELEVEL=0 start
	cd WarehousePG6-from-RPMs-RH7-single-node/ && make MAKELEVEL=0 start
	cd WarehousePG7-from-RPMs-RH9-single-node/ && make MAKELEVEL=0 start
	cd WarehousePG7-from-RPMs-RH9-multi-node/ && make MAKELEVEL=0 start
	cd WarehousePG7-from-RPMs-RH9-multi-node-standby-mirrors/ && make MAKELEVEL=0 start
	cd WarehousePG7-from-RPMs-RH9-single-node-not-installed/ && make MAKELEVEL=0 start
	cd systemd-labs/WarehousePG6-from-RPMs-RH7-single-node-systemd/ && make MAKELEVEL=0 start
	cd systemd-labs/WarehousePG6-from-RPMs-RH8-single-node-systemd/ && make MAKELEVEL=0 start
	cd systemd-labs/WarehousePG6-from-RPMs-RH9-single-node-systemd/ && make MAKELEVEL=0 start
	cd systemd-labs/WarehousePG6-from-source-RH7-single-node-systemd/ && make MAKELEVEL=0 start
	cd systemd-labs/WarehousePG6-from-RPMs-RH7-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 start
	cd systemd-labs/WarehousePG6-from-RPMs-RH8-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 start
	cd systemd-labs/WarehousePG6-from-RPMs-RH9-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 start
	cd systemd-labs/WarehousePG7-from-RPMs-RH8-single-node-systemd/ && make MAKELEVEL=0 start
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-single-node-systemd/ && make MAKELEVEL=0 start
	cd systemd-labs/WarehousePG7-from-source-RH9-single-node-systemd/ && make MAKELEVEL=0 start
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-single-node-not-installed-systemd/ && make MAKELEVEL=0 start
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-multi-node-systemd/ && make MAKELEVEL=0 start
	cd systemd-labs/WarehousePG7-from-RPMs-RH8-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 start
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 start

restart-everything:	docker-running
	cd WarehousePG6-from-source-RH7-single-node/ && make MAKELEVEL=0 restart
	cd WarehousePG7-from-source-RH9-single-node/ && make MAKELEVEL=0 restart
	cd WarehousePG6-from-RPMs-RH7-single-node/ && make MAKELEVEL=0 restart
	cd WarehousePG7-from-RPMs-RH9-single-node/ && make MAKELEVEL=0 restart
	cd WarehousePG7-from-RPMs-RH9-multi-node/ && make MAKELEVEL=0 restart
	cd WarehousePG7-from-RPMs-RH9-multi-node-standby-mirrors/ && make MAKELEVEL=0 restart
	cd WarehousePG7-from-RPMs-RH9-single-node-not-installed/ && make MAKELEVEL=0 restart
	cd systemd-labs/WarehousePG6-from-RPMs-RH7-single-node-systemd/ && make MAKELEVEL=0 restart
	cd systemd-labs/WarehousePG6-from-RPMs-RH8-single-node-systemd/ && make MAKELEVEL=0 restart
	cd systemd-labs/WarehousePG6-from-RPMs-RH9-single-node-systemd/ && make MAKELEVEL=0 restart
	cd systemd-labs/WarehousePG6-from-source-RH7-single-node-systemd/ && make MAKELEVEL=0 restart
	cd systemd-labs/WarehousePG6-from-RPMs-RH7-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 restart
	cd systemd-labs/WarehousePG6-from-RPMs-RH8-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 restart
	cd systemd-labs/WarehousePG6-from-RPMs-RH9-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 restart
	cd systemd-labs/WarehousePG7-from-RPMs-RH8-single-node-systemd/ && make MAKELEVEL=0 restart
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-single-node-systemd/ && make MAKELEVEL=0 restart
	cd systemd-labs/WarehousePG7-from-source-RH9-single-node-systemd/ && make MAKELEVEL=0 restart
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-single-node-not-installed-systemd/ && make MAKELEVEL=0 restart
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-multi-node-systemd/ && make MAKELEVEL=0 restart
	cd systemd-labs/WarehousePG7-from-RPMs-RH8-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 restart
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 restart

clean-everything:	docker-running
	cd WarehousePG6-from-source-RH7-single-node/ && make MAKELEVEL=0 clean
	cd WarehousePG7-from-source-RH9-single-node/ && make MAKELEVEL=0 clean
	cd WarehousePG6-from-RPMs-RH7-single-node/ && make MAKELEVEL=0 clean
	cd WarehousePG7-from-RPMs-RH9-single-node/ && make MAKELEVEL=0 clean
	cd WarehousePG7-from-RPMs-RH9-multi-node/ && make MAKELEVEL=0 clean
	cd WarehousePG7-from-RPMs-RH9-multi-node-standby-mirrors/ && make MAKELEVEL=0 clean
	cd WarehousePG7-from-RPMs-RH9-single-node-not-installed/ && make MAKELEVEL=0 clean
	cd systemd-labs/WarehousePG6-from-RPMs-RH7-single-node-systemd/ && make MAKELEVEL=0 clean
	cd systemd-labs/WarehousePG6-from-RPMs-RH8-single-node-systemd/ && make MAKELEVEL=0 clean
	cd systemd-labs/WarehousePG6-from-RPMs-RH9-single-node-systemd/ && make MAKELEVEL=0 clean
	cd systemd-labs/WarehousePG6-from-source-RH7-single-node-systemd/ && make MAKELEVEL=0 clean
	cd systemd-labs/WarehousePG6-from-RPMs-RH7-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 clean
	cd systemd-labs/WarehousePG6-from-RPMs-RH8-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 clean
	cd systemd-labs/WarehousePG6-from-RPMs-RH9-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 clean
	cd systemd-labs/WarehousePG7-from-RPMs-RH8-single-node-systemd/ && make MAKELEVEL=0 clean
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-single-node-systemd/ && make MAKELEVEL=0 clean
	cd systemd-labs/WarehousePG7-from-source-RH9-single-node-systemd/ && make MAKELEVEL=0 clean
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-single-node-not-installed-systemd/ && make MAKELEVEL=0 clean
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-multi-node-systemd/ && make MAKELEVEL=0 clean
	cd systemd-labs/WarehousePG7-from-RPMs-RH8-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 clean
	cd systemd-labs/WarehousePG7-from-RPMs-RH9-multi-node-standby-mirrors-systemd/ && make MAKELEVEL=0 clean

clean-docker:
	docker image prune --all --force
	docker network prune --force
	docker system prune --all --force

.PHONY: all
.PHONY: docker-running build-everything run-everything status-everything stop-everything start-everything restart-everything clean-everything
.PHONY: clean-data clean-docker
