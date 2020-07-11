#!/usr/bin/env bash
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

################################################################################
# env
export PATH=$PATH:~/.bin
export EDITOR=vim
export TERM=xterm
# Go
export GOROOT="$(asdf where golang)/go"
export GOPATH=~/go
export GO111MODULE=on
export PATH=$PATH:${GOPATH}/bin
# gcloud
export CLOUDSDK_PYTHON="$(asdf where python)/bin/python"
# krew: Package manager for "kubectl plugins" https://krew.dev
export PATH=$PATH:~/.krew/bin
################################################################################
