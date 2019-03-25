#!/usr/bin/env bash
set -e
cd $(dirname $0)
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
        # sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /
        ;;
    "Linux")
        # ubuntu
        #   sudo apt install \
        #   automake autoconf libreadline-dev \
        #   libncurses-dev libssl-dev libyaml-dev \
        #   libxslt-dev libffi-dev libtool unixodbc-dev
        ;;
    esac

    function asdf-plugin-add() {
        toolName=$1
        url=$2
        asdf plugin-add ${toolName} $2 || :
    }

    asdf-plugin-add direnv https://github.com/ryodocx/asdf-direnv.git
    asdf-plugin-add golang
    asdf-plugin-add helm
    asdf-plugin-add kubectl
    asdf-plugin-add nodejs && bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
    asdf-plugin-add python && asdf install python 2.7.16
    asdf-plugin-add terraform
    cd ~
    asdf install
)
################################################################################
