#!/usr/bin/env bash

export SCRIPT=$(readlink -f "$0")
export DIR=$(dirname "$SCRIPT")
cd "$DIR"

./cmd.sh ps $@
