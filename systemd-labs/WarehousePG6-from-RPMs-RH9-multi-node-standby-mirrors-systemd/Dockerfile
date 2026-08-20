# syntax=docker/dockerfile:1

# define arguments as global variables
# ENV settings are scoped locally per build stage, by design
ARG GLOB_MAINTAINER="andreas.scherbaum@enterprisedb.com"
ARG GLOB_DESCRIPTION="Dockerfile to run WarehousePG 6.x"
ARG GLOB_IMAGE_TITLE="WarehousePG"
ARG GLOB_IMAGE_DESCRIPTION="WarehousePG Database image"
ARG GLOB_IMAGE_VERSION="0.1.1"
ARG GLOB_IMAGE_AUTHORS="andreas.scherbaum@enterprisedb.com"
ARG GLOB_MASTER_DATA_DIRECTORY=/whpgdata/master/whpgmne-1
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
ARG GLOB_MASTER_DATA_DIRECTORY

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
ENV MASTER_DATA_DIRECTORY=$GLOB_MASTER_DATA_DIRECTORY
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

# installation goes into /usr/local/greenplum-db-<version>,
# and a symlink to /usr/local/greenplum-db is created
RUN dnf install -y warehouse-pg-6
# clients are already included in the server package
#RUN dnf install -y warehouse-pg-clients
# installation goes into /usr/local/bin
RUN dnf install -y whpg-backup


# switch to gpadmin user, do not build as root
USER gpadmin


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
ARG GLOB_MASTER_DATA_DIRECTORY

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
ENV MASTER_DATA_DIRECTORY=$GLOB_MASTER_DATA_DIRECTORY
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

# systemd is PID 1 in this image (run the container like a real RHEL9 host)
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

# multi-node needs root ssh (administrative gpssh/backup tooling across
# hosts) and a raised connection ceiling: all 5 containers boot in parallel
# and hammer each other with concurrent ssh-copy-id connections during the
# key-exchange bootstrap (see warehousepg-setup.sh), and sshd's default
# "MaxStartups 10:30:100" starts randomly dropping connections past 10
# in flight ("Connection closed by <ip> port 22"), which makes the
# gpinitsystem ssh handshake fail intermittently under emulation.
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config && \
    printf 'MaxStartups 200:30:400\nMaxSessions 200\n' >> /etc/ssh/sshd_config

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8


# add WarehousePG user for building and running the database
RUN groupadd gpadmin
RUN useradd -m -d /home/gpadmin -s /bin/bash -c "WarehousePG Database" -g gpadmin gpadmin
RUN echo "gpadmin ALL=(ALL) NOPASSWD: ALL" | sudo EDITOR='tee -a' visudo
RUN echo "gpadmin:whpg5432" | chpasswd
RUN echo "root:whpg5432" | chpasswd


# expose ports
EXPOSE 22/tcp
EXPOSE 5432/tcp
EXPOSE 6000-6010/tcp
EXPOSE 7000-7010/tcp
EXPOSE 8000-8010/tcp
EXPOSE 9000-9010/tcp
EXPOSE 30000-30010/tcp


# copy installation over from the build stage image
# warehouse-pg-6 installs into /usr/edb/whpg6 and creates a symlink
# /usr/local/greenplum-db -> /usr/edb/whpg6, so both paths must be copied
RUN rm -rf /usr/local/* /usr/edb/*
COPY --from=build-stage /usr/local /usr/local
COPY --from=build-stage /usr/edb /usr/edb

# apparently this does not work everywhere
# and breaks on AWS
#COPY --chown=root:root --chmod=0644 sysctl.conf /etc/sysctl.d/50-warehousepg.conf
#COPY --chown=root:root --chmod=0644 limits.conf /etc/security/limits.d/50-warehousepg.conf


# NOTE: unlike the tail-based image, we stay as root here.
# systemd must run as PID 1 as root; gpadmin is re-entered via the
# warehousepg.service unit's "User=gpadmin".

# WarehousePG 6 tooling (gpinitsystem/gpexpand/etc) is Python 2 based.
# RHEL9/Rocky9 dropped python2 entirely (no OS package, no module stream),
# but EDB ships its own interpreter as "edb-python27" -- warehouse-pg-6
# already pulled it in as a dependency in build-stage (it registers
# /usr/bin/python[2[.7]] via `alternatives`, wired to
# /usr/libexec/edb-python27), so just copy that tree over and redo the
# same alternatives registration here, instead of fighting RHEL's own
# (nonexistent, on el9) python2 packaging.
COPY --from=build-stage /usr/libexec/edb-python27 /usr/libexec/edb-python27
RUN alternatives --install /usr/bin/python python /usr/libexec/edb-python27/bin/python 1 && \
    alternatives --install /usr/bin/python2 python2 /usr/libexec/edb-python27/bin/python2 1 && \
    alternatives --install /usr/bin/python2.7 python2.7 /usr/libexec/edb-python27/bin/python2.7 1

# Create data directories
RUN mkdir -p /whpgdata/master /whpgdata/segments /whpgdata/segments/whpgdata1 /whpgdata/segments/whpgdata2 && \
    chown -R gpadmin:gpadmin /whpgdata


COPY --chown=gpadmin:gpadmin hostfile_whpginitsystem6 /home/gpadmin/hostfile_whpginitsystem
COPY --chown=gpadmin:gpadmin hostfile_segments_whpginitsystem6 /home/gpadmin/hostfile_segments_whpginitsystem
COPY --chown=gpadmin:gpadmin hostfile_ssh_whpginitsystem6 /home/gpadmin/hostfile_ssh_whpginitsystem
COPY --chown=gpadmin:gpadmin whpginitsystem_multinode6 /home/gpadmin/whpginitsystem_multinode
# the chmod option needs buildx
COPY --chown=gpadmin:gpadmin --chmod=0750 warehousepg_init6.sh /home/gpadmin/warehousepg_init.sh
COPY --chown=gpadmin:gpadmin --chmod=0755 list-seg-ports.sh /home/gpadmin/list-seg-ports.sh

# systemd-managed WarehousePG: a first-boot prep script (ssh key exchange
# across all 5 hosts) + a role-branching start script (gpinitsystem/gpstart
# on the coordinator, gpfdist daemon on the gpfdist host, no-op elsewhere)
COPY --chmod=0755 warehousepg-setup.sh /usr/local/bin/warehousepg-setup.sh
COPY --chmod=0755 warehousepg-start.sh /usr/local/bin/warehousepg-start.sh
COPY --chmod=0755 warehousepg-poststart.sh /usr/local/bin/warehousepg-poststart.sh
COPY warehousepg.service /etc/systemd/system/warehousepg.service
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

# Force sshd host-key permissions to 0600 unconditionally on every boot,
# regardless of whether the keys are freshly generated or pre-existing.
# sshd-keygen@.service only fixes perms when key files are absent
# (ConditionFileNotEmpty), so it does nothing if keys already exist but
# have drifted to 0640 -- which has been observed to happen across a real
# Docker Desktop VM restart (not just `docker restart`), even though
# sshd started fine with those same keys moments before. This ExecStartPre
# runs every time sshd.service starts, independent of that condition.
RUN mkdir -p /etc/systemd/system/sshd.service.d && \
    printf '%s\n' '[Service]' 'ExecStartPre=-/bin/sh -c "/bin/chmod 600 /etc/ssh/ssh_host_*_key"' \
      > /etc/systemd/system/sshd.service.d/fix-host-key-perms.conf

RUN systemctl enable sshd.service warehousepg.service


# journald normally keeps entries to itself; without this, "docker logs" /
# the Docker Desktop Logs tab only ever shows the handful of very early
# systemd boot lines PID 1 writes before journald takes over -- every
# service's output (sshd, gpinitsystem, etc) is otherwise invisible outside
# `journalctl`/`make journal`. Forwarding to the console puts it back on
# PID 1's stdout, where Docker's log driver actually reads from.
RUN mkdir -p /etc/systemd/journald.conf.d && \
    printf '[Journal]\nForwardToConsole=yes\nTTYPath=/dev/console\nMaxLevelConsole=info\n' > /etc/systemd/journald.conf.d/forward-to-console.conf

WORKDIR /home/gpadmin

# clean systemd shutdown on `docker stop` -> triggers warehousepg.service ExecStop (gpstop)
STOPSIGNAL SIGRTMIN+3

CMD ["/usr/sbin/init"]
