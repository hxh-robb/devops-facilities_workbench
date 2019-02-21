#!/usr/bin/env bash

export CMD=$(readlink -f "$0")
export DIR=$(dirname "${CMD}")
cd "$DIR"

source _mods.sh $@

[ -x stop.sh ] && ./stop.sh --no-prompt $@ 

TS="$(date -u +%Y%m%d%H%M%S)"

if [ -n "${MODS}" ]; then
  [ "${MODS}" == "NONE" ] && exit 0
  for mod in ${MODS}; do
    echo "=============================="
    echo "Starting service:[${mod}]"
    echo "=============================="
    set -e
    ./cmd.sh up -d --no-recreate --no-color --remove-orphans ${mod}
    echo ""
    refresh_mods_running_file "${DIR}/mods.running"
    set +e
  done
else
  refresh_mods_file "${DIR}/mods"
  echo "=============================="
  echo "Starting all services"
  echo "=============================="
  set -e
  ./cmd.sh up -d --no-color --remove-orphans
  echo ""
  refresh_mods_running_file "${DIR}/mods.running"
  set +e
fi
