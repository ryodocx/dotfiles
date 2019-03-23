#!/usr/bin/env bash

cd $(dirname $0)
ln -sfnv $(pwd)/bin/ ~/.bin
ln -sfnv $(pwd)/bash_completion/ ~/.bash_completion_local

for filepath in $(find files -type f); do
    filepath=${filepath#files/}
    mkdir -p ~/$(dirname ${filepath})
    ln -sfnv $(pwd)/files/${filepath} ~/${filepath}
done
