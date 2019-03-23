#!/bin/bash
set -ex

################################################################################
# asdf
(
    if [ ! -d ~/.asdf ]; then
        git clone https://github.com/asdf-vm/asdf.git ~/.asdf
    fi
    cd ~/.asdf
    git fetch --all
    git checkout "$(git describe --abbrev=0 --tags)"
)
################################################################################
