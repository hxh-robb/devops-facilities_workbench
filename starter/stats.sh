#!/usr/bin/env bash

export SCRIPT=$(readlink -f "$0")
export DIR=$(dirname "$SCRIPT")
cd "$DIR"

#docker stats --no-stream $(./cmd.sh ps -q)
docker stats --no-stream $(./ps.sh -q $@)
