ARG OSIMAGE
FROM ${OSIMAGE:-ubuntu}

ARG WORKDIR="/root"
COPY . ${WORKDIR}/.dotfiles/
WORKDIR ${WORKDIR}

ENV DEBIAN_FRONTEND=noninteractive

RUN ${WORKDIR}/.dotfiles/install.sh
