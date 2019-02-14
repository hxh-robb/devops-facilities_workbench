#!/usr/bin/env bash

CMD=$(readlink -f "$0")
DIR=$(dirname "$CMD")
cd "${DIR}"

git submodule init
git submodule update -f --init --recursive --remote
