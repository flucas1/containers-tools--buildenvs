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

RUN http_proxy="${APTCACHER}" /helpers/setup-fonts-base.sh
RUN mkdir -p /root/mscorefonts
COPY --from=containers-tools ./mscorefonts/ /root/mscorefonts
RUN http_proxy="${APTCACHER}" /helpers/setup-fonts-microsoft.sh
RUN rm -R -f /root/mscorefonts

################################################################################
# sysbench
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/setup-sysbench.sh

################################################################################
# python3
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/setup-python3.sh

################################################################################
# perl
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/apt-retry-install.sh perl

################################################################################
# TeX
################################################################################

RUN http_proxy="${APTCACHER}" /helpers/setup-tex.sh

RUN http_proxy="${APTCACHER}" /helpers/setup-java.sh

RUN http_proxy="${APTCACHER}" /helpers/pip-retry-install.sh --upgrade language-tool-python
ENV LTP_PATH /opt/ltp
RUN mkdir -p /opt/ltp
RUN python3 -c "import language_tool_python; tool=language_tool_python.LanguageTool('en'); tool.close()"

# RUN wget --no-verbose https://www.languagetool.org/download/LanguageTool-stable.zip -O /opt/ltp/lpt-stable.zip
# RUN unzip /opt/ltp/lpt-stable.zip -d /opt/ltp
# RUN rm -f /opt/ltp/lpt-stable.zip

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