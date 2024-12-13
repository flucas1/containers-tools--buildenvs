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
# build containers
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh uidmap
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh fuse-overlayfs
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh containers-storage
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh netavark
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh aardvark-dns

RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh buildah
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh podman
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh skopeo

RUN cp -f /usr/share/containers/storage.conf /etc/containers/storage.conf
#RUN sed -i -e 's|^#mount_program|mount_program|g' /etc/containers/storage.conf
RUN sed -i -e 's|^driver = ""|driver = "overlay"|g' /etc/containers/storage.conf

################################################################################
# buildchain tools
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/setup-exif.sh

################################################################################
# C
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/setup-c.sh

################################################################################
# python3
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/setup-python3.sh

################################################################################
# perl
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh perl

################################################################################
# php
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh php
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh php-cli
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh php-mbstring
RUN http_proxy="${APTCACHER}" /helpers/setup-phpcomposer.sh

################################################################################
# pdf
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh poppler-utils

################################################################################
# documentation
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh asciidoctor

################################################################################
# selenium
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/setup-chromium.sh

RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh python3-selenium

################################################################################
# DEBIANDEV
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh apt-build
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh lintian
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh build-essential

################################################################################
# KUBERNETES
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh yamllint

RUN wget --no-verbose --retry-connrefused --waitretry=1 --tries=10 https://baltocdn.com/helm/signing.asc -O /etc/apt/keyrings/helm.asc
RUN printf "deb [signed-by=/etc/apt/keyrings/helm.asc] https://baltocdn.com/helm/stable/debian/ all main" > /etc/apt/sources.list.d/helm.list
RUN http_proxy="${APTCACHER}" /helpers/apt-update.sh
RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh helm

################################################################################
# .NET
################################################################################

ENV DOTNET_CLI_TELEMETRY_OPTOUT 1
ENV DOTNET_NOLOGO 1
ENV NO_COLOR 1

# RUN wget --no-verbose --retry-connrefused --waitretry=1 --tries=10 https://packages.microsoft.com/keys/microsoft.asc -O /etc/apt/keyrings/netcore.asc
# RUN printf "deb [signed-by=/etc/apt/keyrings/netcore.asc] https://packages.microsoft.com/debian/12/prod $(lsb_release -c | awk '{print $2}') main" > /etc/apt/sources.list.d/netcore.list
# RUN http_proxy="${APTCACHER}" /helpers/apt-update.sh
# RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh dotnet-sdk-6.0 dotnet-sdk-8.0

#RUN mkdir -p /opt/dotnet
## RUN wget --quiet --no-verbose --retry-connrefused --waitretry=3 --tries=20 https://dot.net/v1/dotnet-install.sh -O - | bash /dev/stdin --channel 6.0 --install-dir /opt/dotnet --verbose
## RUN wget --quiet --no-verbose --retry-connrefused --waitretry=3 --tries=20 https://dot.net/v1/dotnet-install.sh -O - | bash /dev/stdin --channel 7.0 --install-dir /opt/dotnet --verbose
## RUN wget --quiet --no-verbose --retry-connrefused --waitretry=3 --tries=20 https://dot.net/v1/dotnet-install.sh -O - | bash /dev/stdin --channel 8.0 --install-dir /opt/dotnet --verbose
#RUN wget --quiet --no-verbose --retry-connrefused --waitretry=3 --tries=20 https://dot.net/v1/dotnet-install.sh -O - | bash /dev/stdin --channel $(wget --quiet --no-verbose --retry-connrefused --waitretry=3 --tries=20 https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/releases-index.json -O - | jq -r '.["releases-index"][] | select(."support-phase"=="active") | ."channel-version"' | sort --version-sort --reverse | head -n 1) --install-dir /opt/dotnet --verbose
#RUN mkdir -p /etc/dotnet
#RUN echo "/opt/dotnet" > /etc/dotnet/install_location

RUN http_proxy="${APTCACHER}" /helpers/setup-dotnetdependencies.sh
RUN http_proxy="${APTCACHER}" /helpers/setup-dotnetlocation.sh
#RUN http_proxy="${APTCACHER}" /helpers/setup-dotnetrepository.sh
RUN http_proxy="${APTCACHER}" /helpers/setup-dotnetsdk.sh
#RUN http_proxy="${APTCACHER}" /helpers/setup-dotnetruntime.sh
#RUN http_proxy="${APTCACHER}" /helpers/setup-dotnetasp.sh

ENV PATH="/opt/dotnet:$PATH"
# do not do ${PATH} -- this is envvar from computer, without {} it is from container

RUN /helpers/setup-dotnetdebugger.sh

RUN /helpers/setup-dotnetextras.sh

RUN python3 /helpers/dotnet-dummyapp.py

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