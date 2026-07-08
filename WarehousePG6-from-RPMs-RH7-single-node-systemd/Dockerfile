# syntax=docker/dockerfile:1

# define arguments as global variables
# ENV settings are scoped locally per build stage, by design
ARG GLOB_MAINTAINER="andreas.scherbaum@enterprisedb.com"
ARG GLOB_DESCRIPTION="Dockerfile to run WarehousePG 6.x"
ARG GLOB_IMAGE_TITLE="WarehousePG"
ARG GLOB_IMAGE_DESCRIPTION="WarehousePG Database image"
ARG GLOB_IMAGE_VERSION="0.1.1"
ARG GLOB_IMAGE_AUTHORS="andreas.scherbaum@enterprisedb.com"
ARG GLOB_MASTER_DATA_DIRECTORY=/whpgdata/master/whpgsne-1
ARG GLOB_WHPGHOME="/usr/local/greenplum-db"


#######################################################################
# use CentOS Linux as base image
FROM centos:7 AS build-stage
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


RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo
RUN sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo
RUN sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# install required packages for building WarehousePG
#RUN localectl set-locale LANG=en_US.UTF-8
RUN yum update -y
RUN yum install -y epel-release
RUN yum update -y
#RUN yum install -y sudo
#RUN yum install -y passwd

COPY rpm-packages-build-step.txt /root/rpm-packages-build-step.txt
RUN yum install -y $(cat /root/rpm-packages-build-step.txt)

RUN yum clean all

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
RUN yum install -y warehouse-pg-6
# clients are already included in the server package
#RUN yum install -y warehouse-pg-clients
# installation goes into /usr/local/bin
RUN yum install -y whpg-backup


# switch to gpadmin user, do not build as root
USER gpadmin


#######################################################################
# database installed, but not started
# build a new image, without the RPMs
FROM centos:7 AS image-stage
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

RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo
RUN sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo
RUN sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# install required packages for running WarehousePG
#RUN localectl set-locale LANG=en_US.UTF-8
RUN yum update -y
RUN yum install -y epel-release
RUN yum update -y

COPY rpm-packages-image-step.txt /root/rpm-packages-image-step.txt
RUN yum install -y $(cat /root/rpm-packages-image-step.txt)

# systemd is PID 1 in this image (run the container like a real RHEL7 host)
RUN yum install -y systemd

RUN yum clean all

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
# the warehouse-pg-6 RPM installs into /usr/edb/whpg6 and only places
# symlinks (greenplum-db, greenplum-db-clients) into /usr/local, so both
# trees must be copied or the symlinks dangle and all binaries go missing
RUN rm -rf /usr/local/* /usr/edb/*
COPY --from=build-stage /usr/local /usr/local
COPY --from=build-stage /usr/edb /usr/edb


# NOTE: unlike the tail-based image, we stay as root here.
# systemd must run as PID 1 as root; gpadmin is re-entered via the
# warehousepg.service unit's "User=gpadmin".

# Create data directories
RUN mkdir -p /whpgdata/master /whpgdata/segments /whpgdata/segments/whpgdata1 /whpgdata/segments/whpgdata2 && \
    chown -R gpadmin:gpadmin /whpgdata


COPY --chown=gpadmin:gpadmin hostfile_whpginitsystem6 /home/gpadmin/hostfile_whpginitsystem
COPY --chown=gpadmin:gpadmin whpginitsystem_singlenode6 /home/gpadmin/whpginitsystem_singlenode
# the chmod option needs buildx
COPY --chown=gpadmin:gpadmin --chmod=0750 warehousepg_init6.sh /home/gpadmin/warehousepg_init.sh

# systemd-managed WarehousePG: a first-boot prep script + a unit that
# runs gpinitsystem (first boot) or gpstart (subsequent boots) as gpadmin
COPY --chmod=0755 warehousepg-setup.sh /usr/local/bin/warehousepg-setup.sh
COPY --chmod=0755 warehousepg-poststart.sh /usr/local/bin/warehousepg-poststart.sh
COPY warehousepg.service /etc/systemd/system/warehousepg.service
RUN systemctl enable sshd.service warehousepg.service

WORKDIR /home/gpadmin

# clean systemd shutdown on `docker stop` -> triggers warehousepg.service ExecStop (gpstop)
STOPSIGNAL SIGRTMIN+3

CMD ["/usr/sbin/init"]
