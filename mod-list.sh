#!/usr/bin/env bash

NAME_ONLY=false
for arg in "$@"; do
  [ "${arg}" == "--name-only" ] && NAME_ONLY=true
done

CMD=$(readlink -f "$0")
DIR=$(dirname "$CMD")
cd "${DIR}"

mkdir -p modules

[ "${NAME_ONLY}" == "true" ] && \
  git submodule status | awk -F'\ |\/|\+' '{print $4}' || \
  git submodule status
