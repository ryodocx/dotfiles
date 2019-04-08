#!/usr/bin/env bash

cd $(dirname $0)/..
docker build -f ./.test/ubuntu.Dockerfile .
# docker build -f ./.test/centos.Dockerfile .
