################################################################################
# baseimage
################################################################################

ARG DEBIANBASE

FROM debian:${DEBIANBASE} as buildenvlinux

ARG APTCACHER

ARG CUSTOMREPOSITORY_IDENTIFIER
ARG CUSTOMREPOSITORY_SERVER
ARG CUSTOMREPOSITORY_PATH

################################################################################
# settings
################################################################################

RUN printf "${http_proxy}\n"
RUN sh -c "printf \"\$http_proxy\\n\""
RUN printf "${APTCACHER}\n"
RUN http_proxy="${APTCACHER}" sh -c "printf \"\$http_proxy\\n\""

RUN mkdir -p /helpers
COPY --from=containers-tools ./helpers/ /helpers
RUN chmod a+x /helpers/*.sh

RUN mkdir -p /helperscache
COPY --from=containers-tools ./helperscache/ /helperscache
RUN chmod -R a+r /helperscache
RUN chmod a+w /helperscache

################################################################################
# apt basic config
################################################################################

ENV TZ=UTC

ENV DEBIAN_FRONTEND noninteractive

RUN http_proxy="${APTCACHER}" /helpers/apt-tuning.sh
RUN http_proxy="${APTCACHER}" /helpers/apt-upgrade.sh

################################################################################
# well-known blocks
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/setup-no-coredumps.sh

RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh tzdata

RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh ca-certificates
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh ssl-cert
#RUN http_proxy="${APTCACHER}" /helpers/remove-snakeoil.sh

RUN http_proxy="${APTCACHER}" /helpers/setup-core.sh
RUN http_proxy="${APTCACHER}" /helpers/setup-mc.sh

################################################################################
# sysbench
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/setup-sysbench.sh

################################################################################
# ESP32
################################################################################

#https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/linux-macos-setup.html

RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh git
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh wget
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh flex
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh bison
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh gperf
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh python3
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh python3-pip
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh python3-venv
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh cmake
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh ninja-build
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh ccache
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh libffi-dev
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh libssl-dev
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh dfu-util
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh libusb-1.0-0

#mkdir -p /esp
#git -C /esp clone --recursive https://github.com/espressif/esp-idf.git
#/esp/esp-idf/install.sh esp32

################################################################################
# install platformio
################################################################################

#https://github.com/tasmota/docker-tasmota

RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh platformio

################################################################################
# install arduino
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh arduino

################################################################################
# install cleanup
################################################################################

RUN /helpers/apt-cleanup.sh
RUN /helpers/remove-helperscache.sh

################################################################################
# extra settings
################################################################################

# entrypoint regenerating snakeoil

RUN adduser jenkins --quiet --disabled-login --home /home/jenkins --gecos ,,,
USER jenkins

################################################################################