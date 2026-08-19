# syntax=docker/dockerfile:1

# define arguments as global variables
# ENV settings are scoped locally per build stage, by design
ARG GLOB_MAINTAINER="andreas.scherbaum@enterprisedb.com"
ARG GLOB_DESCRIPTION="Dockerfile to run WarehousePG 7.x"
ARG GLOB_IMAGE_TITLE="WarehousePG"
ARG GLOB_IMAGE_DESCRIPTION="WarehousePG Database image"
ARG GLOB_IMAGE_VERSION="0.1.1"
ARG GLOB_IMAGE_AUTHORS="andreas.scherbaum@enterprisedb.com"
ARG GLOB_COORDINATOR_DATA_DIRECTORY=/whpgdata/coordinator/whpgsne-1
ARG GLOB_WHPGHOME="/usr/local/greenplum-db"


#######################################################################
# use Rocky Linux as base image
FROM rockylinux:9 AS build-stage
ENV container=docker

ARG GLOB_MAINTAINER
ARG GLOB_DESCRIPTION
ARG GLOB_IMAGE_TITLE
ARG GLOB_IMAGE_DESCRIPTION
ARG GLOB_IMAGE_VERSION
ARG GLOB_IMAGE_AUTHORS
ARG GLOB_OS_NAME
ARG GLOB_OS_VERSION
ARG GLOB_BUILD_VERSION
ARG GLOB_WHPGHOME
#ARG LD_LIBRARY_PATH
ARG GLOB_COORDINATOR_DATA_DIRECTORY

# from commandline arguments
ARG EDBTOKEN
ARG EDBREPOSITORY

# metadata
LABEL maintainer=$GLOB_MAINTAINER
LABEL description=$GLOB_DESCRIPTION
LABEL org.opencontainers.image.title=$GLOB_IMAGE_TITLE
LABEL org.opencontainers.image.description=$GLOB_IMAGE_DESCRIPTION
LABEL org.opencontainers.image.version=$GLOB_BUILD_VERSION
LABEL org.opencontainers.image.authors=$GLOB_IMAGE_AUTHORS


# set environment variables
# start with C locale here, change to US later
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
# configure environment for WarehousePG
ENV OS_NAME=$GLOB_OS_NAME
ENV OS_VERSION=$GLOB_OS_VERSION
ENV BUILD_VERSION=$GLOB_BUILD_VERSION
ENV WHPGHOME=$GLOB_WHPGHOME
#ENV LD_LIBRARY_PATH=$WHPGHOME/lib:$LD_LIBRARY_PATH
ENV COORDINATOR_DATA_DIRECTORY=$GLOB_COORDINATOR_DATA_DIRECTORY
ENV PATH=$WHPGHOME/bin:$PATH


# download setup.rpm.sh early on, which will fail early if the token doesn't work
RUN --mount=type=secret,id=edbtoken_secret --mount=type=secret,id=edbrepository_secret curl -u token:$(cat /run/secrets/edbtoken_secret) -1sLf https://downloads.enterprisedb.com/basic/$(cat /run/secrets/edbrepository_secret)/setup.rpm.sh -o /root/setup.rpm.sh


# install required packages for building WarehousePG
#RUN localectl set-locale LANG=en_US.UTF-8
RUN dnf update -y
RUN dnf install -y epel-release
RUN dnf update -y
#RUN dnf install -y sudo
#RUN dnf install -y passwd

COPY rpm-packages-build-step.txt /root/rpm-packages-build-step.txt
RUN dnf install -y $(cat /root/rpm-packages-build-step.txt)

RUN dnf clean all

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8


# add gpadmin user for building the database
RUN groupadd gpadmin
RUN useradd -m -d /home/gpadmin -s /bin/bash -c "WarehousePG Database" -g gpadmin gpadmin
RUN echo "gpadmin ALL=(ALL) NOPASSWD: ALL" | sudo EDITOR='tee -a' visudo


# install the database from RPM
RUN chmod u+x /root/setup.rpm.sh
RUN /root/setup.rpm.sh

RUN mkdir /root/rpm-downloads
RUN dnf install -y --downloadonly --downloaddir=/root/rpm-downloads warehouse-pg-7
RUN dnf install -y --downloadonly --downloaddir=/root/rpm-downloads warehouse-pg-clients
RUN dnf install -y --downloadonly --downloaddir=/root/rpm-downloads whpg-backup


#######################################################################
# database installed, but not started
# build a new image, without the RPMs
FROM rockylinux:9 AS image-stage
ENV container=docker

ARG GLOB_MAINTAINER
ARG GLOB_DESCRIPTION
ARG GLOB_IMAGE_TITLE
ARG GLOB_IMAGE_DESCRIPTION
ARG GLOB_IMAGE_VERSION
ARG GLOB_IMAGE_AUTHORS
ARG GLOB_OS_NAME
ARG GLOB_OS_VERSION
ARG GLOB_BUILD_VERSION
ARG GLOB_WHPGHOME
#ARG LD_LIBRARY_PATH
ARG GLOB_COORDINATOR_DATA_DIRECTORY

# metadata
LABEL maintainer=$GLOB_MAINTAINER
LABEL description=$GLOB_DESCRIPTION
LABEL org.opencontainers.image.title=$GLOB_IMAGE_TITLE
LABEL org.opencontainers.image.description=$GLOB_IMAGE_DESCRIPTION
LABEL org.opencontainers.image.version=$GLOB_BUILD_VERSION
LABEL org.opencontainers.image.authors=$GLOB_IMAGE_AUTHORS

# set environment variables
# start with C locale here, change to US later
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
# configure environment for WarehousePG
ENV OS_NAME=$GLOB_OS_NAME
ENV OS_VERSION=$GLOB_OS_VERSION
ENV BUILD_VERSION=$GLOB_BUILD_VERSION
ENV WHPGHOME=$GLOB_WHPGHOME
#ENV LD_LIBRARY_PATH=$WHPGHOME/lib:$LD_LIBRARY_PATH
ENV COORDINATOR_DATA_DIRECTORY=$GLOB_COORDINATOR_DATA_DIRECTORY
ENV PATH=$WHPGHOME/bin:$PATH

# install required packages for running WarehousePG
#RUN localectl set-locale LANG=en_US.UTF-8
RUN dnf update -y
RUN dnf groupinstall -y "Development Tools"
RUN dnf install -y epel-release
RUN dnf update -y

COPY rpm-packages-image-step.txt /root/rpm-packages-image-step.txt
RUN dnf install -y $(cat /root/rpm-packages-image-step.txt)

RUN dnf install -y --enablerepo=crb libyaml libyaml-devel libuv-devel perl-IPC-Run

# the following packages will otherwise be installed as dependency
# which does not survive a restart
RUN dnf install -y apr-util apr-util-bdb apr-util-openssl llvm15-libs python3-psycopg2

# systemd is PID 1 in this image (run the container like a real RHEL9 host)
# NOTE: this lab has no warehousepg.service -- WarehousePG is intentionally
# left RPM-downloaded-but-not-installed, so trainees install and
# gpinitsystem it by hand. systemd + sshd just gives them a realistic,
# systemd-managed OS to do that on.
RUN dnf install -y systemd openssh-server

RUN dnf clean all

# strip the units a container never needs (getty, login prompts, udev, etc.)
# so the journal isn't full of failures for hardware that doesn't exist
RUN (cd /lib/systemd/system/sysinit.target.wants/; \
       for i in *; do [ "$i" = systemd-tmpfiles-setup.service ] || rm -f "$i"; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*; \
    rm -f /lib/systemd/system/anaconda.target.wants/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8


# add WarehousePG user for building and running the database
RUN groupadd gpadmin
RUN useradd -m -d /home/gpadmin -s /bin/bash -c "WarehousePG Database" -g gpadmin gpadmin
RUN echo "gpadmin ALL=(ALL) NOPASSWD: ALL" | sudo EDITOR='tee -a' visudo


# expose ports
EXPOSE 22/tcp
EXPOSE 5432/tcp
EXPOSE 6000-6010/tcp
EXPOSE 7000-7010/tcp
EXPOSE 8000-8010/tcp
EXPOSE 9000-9010/tcp
EXPOSE 30000-30010/tcp


# copy installation over from the build stage image
COPY --from=build-stage /root/rpm-downloads /root/rpm-downloads


# NOTE: unlike the tail-based image, we stay as root here.
# systemd must run as PID 1 as root. There is no warehousepg.service
# in this lab (nothing is installed or auto-started) -- the trainee
# becomes gpadmin themselves via `docker compose exec ... su - gpadmin`
# once they're ready to install the RPMs and run gpinitsystem by hand.


COPY --chown=gpadmin:gpadmin hostfile_whpginitsystem7 /home/gpadmin/hostfile_whpginitsystem
COPY --chown=gpadmin:gpadmin whpginitsystem_singlenode7 /home/gpadmin/whpginitsystem_singlenode
# the chmod option needs buildx
COPY --chown=gpadmin:gpadmin --chmod=0750 warehousepg_init7.sh /home/gpadmin/warehousepg_init.sh
WORKDIR /home/gpadmin


# populate ~/.bash_history with common commands
# do this here, because there is no cmd.sh to run these
RUN touch /home/gpadmin/.bash_history
RUN chown gpadmin:gpadmin /home/gpadmin/.bash_history
RUN chmod 0600 /home/gpadmin/.bash_history
RUN echo "source /usr/local/greenplum-db/greenplum_path.sh" >> /home/gpadmin/.bash_history
RUN echo "psql whpgtest" >> /home/gpadmin/.bash_history
RUN echo "sudo /bin/bash --login" >> /home/gpadmin/.bash_history
RUN echo "gpstart -a" >> /home/gpadmin/.bash_history
RUN echo "gpstop -a -M fast" >> /home/gpadmin/.bash_history
RUN echo "gpstate -a" >> /home/gpadmin/.bash_history


# populate ~/.psql_history with common commands
RUN touch /home/gpadmin/.psql_history
RUN chown gpadmin:gpadmin /home/gpadmin/.psql_history
RUN chmod 0600 /home/gpadmin/.psql_history
RUN echo "SELECT version();" >> /home/gpadmin/.psql_history
RUN echo "SELECT * from gp_segment_configuration;" >> /home/gpadmin/.psql_history


# no warehousepg.service to enable here -- nothing is installed or
# configured yet, so there's nothing to auto-start. Only sshd, so the
# trainee gets a realistic systemd-managed OS to install/gpinitsystem by hand.
# The openssh-server RPM's post-install script bakes host keys into the
# image at build time with mode 0640 (group-readable). sshd hard-refuses
# to start with keys that permissive ("Permissions 0640 for ... are too
# open" -> "no hostkeys available -- exiting"), which cascades into
# warehousepg.service failing on every node ("sshd on host <X> is not
# available!"). Because the keys are baked in (not absent),
# sshd-keygen@.service's ConditionFileNotEmpty=|!/etc/ssh/ssh_host_%i_key
# never fires to fix them on boot -- this bites every fresh container. Fix
# it once at the source: drop the baked-in keys so each container
# generates its own correctly-permissioned (0600) host keys on first boot.
RUN rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub

RUN systemctl enable sshd.service


# journald normally keeps entries to itself; without this, "docker logs" /
# the Docker Desktop Logs tab only ever shows the handful of very early
# systemd boot lines PID 1 writes before journald takes over -- every
# service's output (sshd, etc) is otherwise invisible outside
# `journalctl`. Forwarding to the console puts it back on PID 1's stdout,
# where Docker's log driver actually reads from.
RUN mkdir -p /etc/systemd/journald.conf.d && \
    printf '[Journal]\nForwardToConsole=yes\nTTYPath=/dev/console\nMaxLevelConsole=info\n' > /etc/systemd/journald.conf.d/forward-to-console.conf

# clean systemd shutdown on `docker stop`
STOPSIGNAL SIGRTMIN+3

CMD ["/usr/sbin/init"]
