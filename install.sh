#!/usr/bin/env bash
set -e
cd $(dirname $0)
type sudo &>/dev/null && sudo=sudo
mkdir -p ~/go/src

################################################################################
# basic packages
(
    case "$(uname -s)" in
    "Darwin")
        # brew
        type brew &>/dev/null || {
            xcode-select --install ||
                ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        }

        brew upgrade

        brew install \
            bash \
            curl \
            openssh \
            vim \
            git \
            watch \
            bash-completion

        brew cask install \
            keepassxc

        # enable bash
        if [ -z "${CI}" ]; then
            grep /usr/local/bin/bash /etc/shells || {
                echo '1. sudo vi /etc/shells & add "/usr/local/bin/bash" last line.'
                echo '2. chsh -s /usr/local/bin/bash'
                exit 1
            }

        fi
        ;;
    "Linux")
        if type yum &>/dev/null; then
            # ${sudo} yum update -y
            ${sudo} yum install -y \
                curl \
                openssh-clients \
                vim \
                git \
                bash-completion
        elif type apt &>/dev/null; then
            ${sudo} apt update -y
            ${sudo} apt install -y \
                curl \
                openssh-client \
                vim \
                git \
                bash-completion
        fi
        ;;
    esac
)
################################################################################
# https://github.com/zeit/hyper
(
    case "$(uname -s)" in
    "Darwin")
        brew cask install hyper
        ;;
    "Linux")
        if type yum &>/dev/null; then
            :
        elif type apt &>/dev/null; then
            :
        fi
        ;;
    esac
)
################################################################################
# snap
# (
#     case "$(uname -s)" in
#     "Darwin")
#         :
#         ;;
#     "Linux")
#         if type yum &>/dev/null; then
#             type snap &>/dev/null || {
#                 ${sudo} yum -y install epel-release yum-plugin-copr
#                 ${sudo} yum -y copr enable ngompa/snapcore-el7
#                 ${sudo} yum -y install snapd
#                 ${sudo} systemctl enable --now snapd.socket ||
#                     ${sudo} ln -sfv /var/lib/snapd/snap /snap
#             }
#         elif
#             type apt &>/dev/null
#         then
#             ${sudo} apt install -y snapd
#         fi
#         ;;
#     esac
# )
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
            unzip
        # python
        brew install \
            openssl \
            readline \
            sqlite3 \
            xz \
            zlib
        if [ -z "${CI}" ]; then
            sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /
        fi
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
            # python
            ${sudo} apt install -y \
                make \
                build-essential \
                libssl-dev \
                zlib1g-dev \
                libbz2-dev \
                libreadline-dev \
                libsqlite3-dev \
                wget \
                curl \
                llvm \
                libncurses5-dev \
                xz-utils \
                tk-dev \
                libxml2-dev \
                libxmlsec1-dev \
                libffi-dev \
                liblzma-dev
        fi
        ;;
    esac

    function asdf-plugin-add() {
        toolName=$1
        url=$2
        asdf plugin-add ${toolName} ${url} || :
    }

    asdf-plugin-add direnv https://github.com/ryodocx/asdf-direnv
    asdf-plugin-add docker-compose https://github.com/virtualstaticvoid/asdf-docker-compose.git
    asdf-plugin-add ghq https://github.com/ryodocx/asdf-ghq
    asdf-plugin-add golang
    asdf-plugin-add helm
    asdf-plugin-add jq https://github.com/ryodocx/asdf-jq
    asdf-plugin-add kubectl
    asdf-plugin-add nodejs && bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring 2>/dev/null || :
    asdf-plugin-add peco https://github.com/ryodocx/asdf-peco
    asdf-plugin-add protoc
    asdf-plugin-add python
    asdf-plugin-add terraform
    asdf-plugin-add vault
)
################################################################################
# Docker
if [ -z "${CI}" ]; then
    case "$(uname -s)" in
    "Darwin")
        :
        ;;
    "Linux")
        if type yum &>/dev/null; then
            :
        elif type apt &>/dev/null; then
            ${sudo} apt -y install \
                apt-transport-https \
                ca-certificates \
                curl \
                gnupg2 \
                software-properties-common
            curl -fsSL https://download.docker.com/linux/debian/gpg | ${sudo} apt-key add -
            if grep ubuntu /etc/os-release 1>/dev/null; then
                ${sudo} add-apt-repository \
                    "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            elif grep debian /etc/os-release 1>/dev/null; then
                ${sudo} add-apt-repository \
                    "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
            fi
            ${sudo} apt -y update
            ${sudo} apt -y install docker-ce docker-ce-cli containerd.io
        fi
        ;;
    esac
fi
################################################################################
echo "install completed!"
exit 0
