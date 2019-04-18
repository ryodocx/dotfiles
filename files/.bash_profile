#!/usr/bin/env bash
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

################################################################################
# env
export PATH=$PATH:~/.bin
export EDITOR=code # VSCode
export TERM=xterm
# Go
export GOROOT=${ASDFINSTALLS}/golang/1.12.2/go
export GOPATH=~/go
export GO111MODULE=on
export PATH=$PATH:${GOPATH}/bin
# gcloud
export CLOUDSDK_PYTHON=${ASDFINSTALLS}/python/2.7.16/bin/python
# krew: Package manager for "kubectl plugins" https://krew.dev
export PATH=$PATH:~/.krew/bin
################################################################################
