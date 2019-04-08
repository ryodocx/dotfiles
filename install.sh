#!/usr/bin/env bash
set -e
cd $(dirname $0)

################################################################################
# basic packages
(
    case "$(uname -s)" in
    "Darwin")
        brew install \
            curl \
            git ||
            :
        ;;
    "Linux")
        type sudo &>/dev/null && sudo su
        if type yum &>/dev/null; then
            yum update -y
            yum install -y \
                curl \
                git ||
                :
        elif type apt &>/dev/null; then
            apt update -y
            apt install -y \
                curl \
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
            unixodbc \
            unzip ||
            :
        ;;
    "Linux")
        type sudo &>/dev/null && sudo su
        if type yum &>/dev/null; then
            yum install -y \
                make \
                automake \
                autoconf \
                libtool \
                unzip
            # nodejs
            yum install -y \
                perl-Digest-SHA
            # python
            yum install -y \
                gcc \
                zlib-devel \
                bzip2 \
                bzip2-devel \
                readline \
                readline-devel \
                sqlite \
                sqlite-devel \
                openssl \
                openssl-devel
        elif type apt &>/dev/null; then
            apt install -y \
                automake \
                autoconf \
                libreadline-dev \
                libncurses-dev \
                libssl-dev \
                libyaml-dev \
                libxslt-dev \
                libffi-dev \
                libtool \
                unixodbc-dev \
                unzip
        fi
        ;;
    esac

    function asdf-plugin-add() {
        toolName=$1
        url=$2
        asdf plugin-add ${toolName} ${url} || :
    }

    asdf-plugin-add direnv https://github.com/ryodocx/asdf-direnv
    asdf-plugin-add ghq https://github.com/ryodocx/asdf-ghq
    asdf-plugin-add golang
    asdf-plugin-add helm
    asdf-plugin-add jq https://github.com/ryodocx/asdf-jq
    asdf-plugin-add kubectl
    asdf-plugin-add nodejs && bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
    asdf-plugin-add peco https://github.com/ryodocx/asdf-peco
    asdf-plugin-add protoc
    asdf-plugin-add python && asdf install python 2.7.16
    asdf-plugin-add terraform
    cd ~
    asdf install
)
################################################################################
