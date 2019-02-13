#!/usr/bin/env bash

SCRIPT=`readlink -f "$0"`
DIR=`dirname "$SCRIPT"`
cd "$DIR"

git submodule init
git submodule update -f --init --recursive --remote
