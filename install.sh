#!/usr/bin/env bash
set -e
cd $(dirname $0)
type sudo &>/dev/null && sudo=sudo

################################################################################
# basic packages
(
    case "$(uname -s)" in
    "Darwin")
        # brew
        type brew &>/dev/null || {
            xcode-select --install
            ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        }

        brew install \
            bash \
            curl \
            openssh \
            vim \
            git ||
            :

        # enable bash
        grep /usr/local/bin/bash /etc/shells || {
            ${sudo} echo '/usr/local/bin/bash' >>/etc/shells
            chsh -s /usr/local/bin/bash
        }
        ;;
    "Linux")
        if type yum &>/dev/null; then
            ${sudo} yum update -y
            ${sudo} yum install -y \
                curl \
                openssh-clients \
                vim \
                git ||
                :
        elif type apt &>/dev/null; then
            ${sudo} apt update -y
            ${sudo} apt install -y \
                curl \
                openssh-client \
                vim \
                git ||
                :
        fi
        ;;
    esac
)
################################################################################
# snap
(
    case "$(uname -s)" in
    "Darwin")
        :
        ;;
    "Linux")
        if type yum &>/dev/null; then
            type snap &>/dev/null || {
                ${sudo} yum -y install epel-release yum-plugin-copr
                ${sudo} yum -y copr enable ngompa/snapcore-el7
                ${sudo} yum -y install snapd
                ${sudo} systemctl enable --now snapd.socket
                ${sudo} ln -s /var/lib/snapd/snap /snap
            }
        elif
            type apt &>/dev/null
        then
            ${sudo} apt install -y snapd
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
        if type yum &>/dev/null; then
            ${sudo} yum install -y \
                make \
                automake \
                autoconf \
                libtool \
                unzip
            # nodejs
            ${sudo} yum install -y \
                perl-Digest-SHA
            # python
            ${sudo} yum install -y \
                gcc \
                zlib-devel \
                bzip2 \
                bzip2-devel \
                readline \
                readline-devel \
                sqlite \
                sqlite-devel \
                openssl \
                openssl-devel \
                libffi-devel
        elif type apt &>/dev/null; then
            ${sudo} apt install -y \
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
    asdf-plugin-add vault
    cd ~
    asdf install
)
################################################################################
# go get
(
    exec $SHELL
    go get github.com/jessfraz/netscan
)
################################################################################
