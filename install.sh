#!/usr/bin/env bash
set -ex
cd $(dirname $0)

################################################################################
# basic packages
(
    case "$(uname -s)" in
    "Darwin")
        brew install \
            git ||
            :
        ;;
    "Linux")
        type sudo &>/dev/null && sudo su
        if type yum &>/dev/null; then
            yum update -y
            yum install -y \
                git ||
                :
        elif type apt &>/dev/null; then
            apt update -y
            apt install -y \
                git ||
                :
        fi
        ;;
    esac
)
################################################################################
# asdf
(
    if [ ! -d ~/.asdf ]; then
        git clone https://github.com/asdf-vm/asdf.git ~/.asdf
    fi
    . ~/.asdf/asdf.sh
    . ~/.asdf/completions/asdf.bash
    asdf update

    case "$(uname -s)" in
    "Darwin")
        brew install \
            coreutils \
            automake \
            autoconf \
            openssl \
            libyaml \
            readline \
            libxslt \
            libtool \
            gpg \
            unixodbc ||
            :
        ;;
    "Linux")
        type sudo &>/dev/null && sudo su
        if type yum &>/dev/null; then
            yum install -y \
                automake autoconf libreadline-dev \
                libncurses-dev libssl-dev libyaml-dev \
                libxslt-dev libffi-dev libtool unixodbc-dev
        elif type apt &>/dev/null; then
            apt install -y \
                automake autoconf libreadline-dev \
                libncurses-dev libssl-dev libyaml-dev \
                libxslt-dev libffi-dev libtool unixodbc-dev
        fi
        ;;
    esac

    function asdf-plugin-add() {
        toolName=$1
        url=$2
        asdf plugin-add ${toolName} ${url} || :
    }

    asdf-plugin-add direnv https://github.com/ryodocx/asdf-direnv.git
    asdf-plugin-add ghq https://github.com/ryodocx/asdf-ghq.git
    asdf-plugin-add golang
    asdf-plugin-add helm
    asdf-plugin-add jq https://github.com/ryodocx/asdf-jq.git
    asdf-plugin-add kubectl
    asdf-plugin-add nodejs && bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
    asdf-plugin-add peco https://github.com/ryodocx/asdf-peco.git
    asdf-plugin-add protoc
    asdf-plugin-add python && asdf install python 2.7.16
    asdf-plugin-add terraform
    cd ~
    asdf install
)
################################################################################
