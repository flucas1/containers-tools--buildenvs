################################################################################
# baseimage
################################################################################

ARG DEBIANBASE

FROM debian:${DEBIANBASE} as buildenvwine

ARG DEBIANBASE
ARG APTCACHER
ARG WINEGRAPE
ARG WINEVERSION
ARG MULTIARCH
ARG WINEARCH
ARG DIRECTINSTALL
ARG INSTALL_MSCOREFONTS
ARG INSTALL_VCRUN
ARG INSTALL_VBRUN
ARG INSTALL_DOTNETFRAMEWORK
ARG INSTALL_DOTNETCORE
ARG INSTALL_DOTNETDUMMYAPP
ARG INSTALL_DOTNETEXTRAS
ARG INSTALL_WINDOWSPOWERSHELL
ARG INSTALL_POWERSHELL
ARG INSTALL_MSBUILDTOOLS
ARG INSTALL_MSYS2
ARG INSTALL_PYTHON3
ARG INSTALL_PIP

ARG CUSTOMREPOSITORY_IDENTIFIER
ARG CUSTOMREPOSITORY_SERVER
ARG CUSTOMREPOSITORY_PATH

ARG VERSION_DOTNETCORE_PREVIEW

################################################################################
# settings
################################################################################

RUN printf "${WINEGRAPE}\n"
RUN printf "${WINEVERSION}\n"

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

RUN http_proxy="${APTCACHER}" /helpers/apt-tuning.sh ${DEBIANBASE}
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

RUN http_proxy="${APTCACHER}" /helpers/setup-locales.sh
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN http_proxy="${APTCACHER}" /helpers/setup-fonts-base.sh
RUN mkdir -p /root/mscorefonts
COPY --from=containers-tools ./mscorefonts/ /root/mscorefonts
RUN if [ "${INSTALL_MSCOREFONTS}"       = "yes" ] ; then http_proxy="${APTCACHER}" /helpers/setup-fonts-microsoft.sh ; fi
RUN rm -R -f /root/mscorefonts

################################################################################
# sysbench
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/setup-sysbench.sh

################################################################################
# signing tools
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/setup-signing.sh

################################################################################
# VULKAN
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/setup-vulkan.sh

################################################################################
# X
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/setup-x.sh

################################################################################
# WINE
################################################################################

COPY --from=containers-tools ./winecache/gecko/ /usr/share/wine/gecko/
COPY --from=containers-tools ./winecache/mono/ /usr/share/wine/mono/
RUN http_proxy="${APTCACHER}" /helpers/setup-wine.sh "${WINEGRAPE}" "${WINEVERSION}" "${MULTIARCH}"

RUN http_proxy="${APTCACHER}" /helpers/setup-verisign.sh

################################################################################
# WINEPREFIX
################################################################################

RUN adduser wineuser --quiet --disabled-login --home /home/wineuser --gecos ,,,
RUN mkdir -p /wineprefix
RUN chown -R wineuser:wineuser /wineprefix
WORKDIR /home/wineuser
USER wineuser

#ENV WINEDEBUG="fixme-all"
#ENV WINEDEBUG="+loaddll"
ENV WINEPREFIX="/wineprefix"
ENV WINEARCH="${WINEARCH}"
#ENV WINEDLLOVERRIDES="mscoree=n;mshtml=n"
#ENV LC_ALL="C"
ENV DBUS_FATAL_WARNINGS="0"

ENV WINEDLLOVERRIDES=""
ENV WINETRICKS_SUPER_QUIET="1"
ENV WINETRICKS_DOWNLOADER="curl"

RUN /helpers/wine-boot.sh

################################################################################
# extra certificates
################################################################################

RUN /helpers/wine-digicert.sh

################################################################################
# vc redist
################################################################################

COPY --from=containers-tools --chown=wineuser:wineuser ./winetricks/vcrun2008/ ./.cache/winetricks/vcrun2008/
COPY --from=containers-tools --chown=wineuser:wineuser ./winetricks/vcrun2019/ ./.cache/winetricks/vcrun2019/
RUN if [ "${INSTALL_VCRUN}"             = "yes" ] ; then http_proxy="${APTCACHER}" /helpers/wine-vcredist.sh          "${DIRECTINSTALL}" ; fi
RUN rm -R -f ./.cache/winetricks/vcrun2008/
RUN rm -R -f ./.cache/winetricks/vcrun2019/

################################################################################
# vb redist
################################################################################

COPY --from=containers-tools --chown=wineuser:wineuser ./winetricks/vb6run/ ./.cache/winetricks/vb6run/
RUN if [ "${INSTALL_VBRUN}"             = "yes" ] ; then http_proxy="${APTCACHER}" /helpers/wine-vbredist.sh          "${DIRECTINSTALL}" ; fi
RUN rm -R -f ./.cache/winetricks/vb6run/

################################################################################
# dotnet framework
################################################################################

COPY --from=containers-tools --chown=wineuser:wineuser ./winetricks/dotnet20sp2/ /home/wineuser/.cache/winetricks/dotnet20sp2/
COPY --from=containers-tools --chown=wineuser:wineuser ./winetricks/dotnet35sp1/ /home/wineuser/.cache/winetricks/dotnet35sp1/
COPY --from=containers-tools --chown=wineuser:wineuser ./winetricks/dotnet40/ /home/wineuser/.cache/winetricks/dotnet40/
COPY --from=containers-tools --chown=wineuser:wineuser ./winetricks/dotnet452/ /home/wineuser/.cache/winetricks/dotnet452/
COPY --from=containers-tools --chown=wineuser:wineuser ./winetricks/dotnet462/ /home/wineuser/.cache/winetricks/dotnet462/
COPY --from=containers-tools --chown=wineuser:wineuser ./winetricks/dotnet472/ /home/wineuser/.cache/winetricks/dotnet472/
COPY --from=containers-tools --chown=wineuser:wineuser ./winetricks/dotnet48/ /home/wineuser/.cache/winetricks/dotnet48/
RUN if [ "${INSTALL_DOTNETFRAMEWORK}"   = "yes" ] ; then http_proxy="${APTCACHER}" /helpers/wine-dotnetframework.sh   "${DIRECTINSTALL}" ; fi
RUN rm -R -f /home/wineuser/.cache/winetricks/dotnet20sp2/
RUN rm -R -f /home/wineuser/.cache/winetricks/dotnet35sp1/
RUN rm -R -f /home/wineuser/.cache/winetricks/dotnet40/
RUN rm -R -f /home/wineuser/.cache/winetricks/dotnet452/
RUN rm -R -f /home/wineuser/.cache/winetricks/dotnet462/
RUN rm -R -f /home/wineuser/.cache/winetricks/dotnet472/
RUN rm -R -f /home/wineuser/.cache/winetricks/dotnet48/

################################################################################
# windows powershell
################################################################################

COPY --from=containers-tools --chown=wineuser:wineuser ./winetricks/powershell10/ /home/wineuser/.cache/winetricks/powershell10/
COPY --from=containers-tools --chown=wineuser:wineuser ./winetricks/powershell20/ /home/wineuser/.cache/winetricks/powershell20/
RUN if [ "${INSTALL_WINDOWSPOWERSHELL}" = "yes" ] ; then http_proxy="${APTCACHER}" /helpers/wine-windowspowershell.sh "${DIRECTINSTALL}" ; fi
RUN rm -R -f /home/wineuser/.cache/winetricks/powershell10/
RUN rm -R -f /home/wineuser/.cache/winetricks/powershell20/

################################################################################
# python3 on wine
################################################################################

COPY --from=containers-tools --chown=wineuser:wineuser ./pythoncache/ /home/wineuser/.cache/pythoncache/

RUN if [ "${INSTALL_PYTHON3}"           = "yes" ] ; then http_proxy="${APTCACHER}" /helpers/wine-python3.sh           "${DIRECTINSTALL}" /home/wineuser/.cache/pythoncache ; fi

RUN rm -R -f /home/wineuser/.cache/pythoncache/

################################################################################
# .NET CORE SDK
################################################################################

COPY --from=containers-tools --chown=wineuser:wineuser ./dotnetcache/ /home/wineuser/.cache/dotnetcache/

RUN if [ "${INSTALL_DOTNETCORE}"        = "yes" ] ; then http_proxy="${APTCACHER}" /helpers/wine-dotnetsdk.sh         "${DIRECTINSTALL}" "$( if [ "${VERSION_DOTNETCORE_PREVIEW}" = "" ] ; then echo preview ; else echo "${VERSION_DOTNETCORE_PREVIEW}" ; fi )" /home/wineuser/.cache/dotnetcache ; fi
RUN if [ "${INSTALL_DOTNETCORE}"        = "yes" ] ; then http_proxy="${APTCACHER}" /helpers/wine-dotnetsdk.sh         "${DIRECTINSTALL}" newest /home/wineuser/.cache/dotnetcache ; fi

RUN if [ "${INSTALL_DOTNETCORE}"        = "yes" ] ; then http_proxy="${APTCACHER}" /helpers/wine-dotnetdebugger.sh    "${DIRECTINSTALL}" /home/wineuser/.cache/dotnetcache ; fi

RUN rm -R -f /home/wineuser/.cache/dotnetcache/

################################################################################
# dotnet-extras
################################################################################

RUN if [ "${INSTALL_DOTNETEXTRAS}"      = "yes" ] ; then http_proxy="${APTCACHER}" /helpers/wine-dotnetextras.sh /dev/null ; fi

################################################################################
# dotnet-dummyapp
################################################################################

RUN if [ "${INSTALL_DOTNETDUMMYAPP}"    = "yes" ] ; then http_proxy="${APTCACHER}" /helpers/wine-dotnet-dummyapp.sh /dev/null ; fi

################################################################################
# wix
################################################################################

RUN if [ "${INSTALL_DOTNETEXTRAS}"      = "yes" ] ; then http_proxy="${APTCACHER}" /helpers/wine-wix.sh /dev/null ; fi

################################################################################
# powershell
################################################################################

RUN if [ "${INSTALL_POWERSHELL}"        = "yes" ] ; then http_proxy="${APTCACHER}" /helpers/wine-powershell.sh        "${DIRECTINSTALL}" ; fi

################################################################################
# MS build tools
################################################################################

RUN if [ "${INSTALL_MSBUILDTOOLS}"      = "yes" ] ; then http_proxy="${APTCACHER}" /helpers/wine-msbuildtools.sh      "${DIRECTINSTALL}" ; fi

################################################################################
# msys2
################################################################################

RUN if [ "${INSTALL_MSYS2}"             = "yes" ] ; then http_proxy="${APTCACHER}" /helpers/wine-msys2.sh             "${DIRECTINSTALL}" ; fi

################################################################################
# PIP packages
################################################################################

RUN if [ "${INSTALL_PIP}"               = "yes" ] ; then http_proxy="${APTCACHER}" /helpers/wine-pip.sh               "${DIRECTINSTALL}" ; fi

################################################################################
# final checks
################################################################################

RUN /helpers/wine-checks.sh

################################################################################
# back to root
################################################################################

USER root

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
