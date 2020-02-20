#!/usr/bin/env bash
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

################################################################################
# env
ASDFINSTALLS=~/.asdf/installs

export PATH=$PATH:~/.bin
export EDITOR=code # VSCode
export TERM=xterm
# Go
export GOROOT=${ASDFINSTALLS}/golang/$(basename $(asdf where golang))/go
export GOPATH=~/go
export GO111MODULE=on
export PATH=$PATH:${GOPATH}/bin
# gcloud
export CLOUDSDK_PYTHON=${ASDFINSTALLS}/python/$(basename $(asdf where python))/bin/python
# krew: Package manager for "kubectl plugins" https://krew.dev
export PATH=$PATH:~/.krew/bin
################################################################################
