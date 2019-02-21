#!/usr/bin/env bash

export CMD=$(readlink -f "$0")
export DIR=$(dirname "${CMD}")
cd "$DIR"

source _mods.sh $@

TS="$(date -u +%Y%m%d%H%M%S)"

if [ -n "${MODS}" ]; then
  [ "${MODS}" == "NONE" ] && exit 0
  
  for mod in ${MODS}; do
    echo "=============================="
    echo "Stopping service:[${mod}]"
    echo "=============================="
    ./cmd.sh stop "${mod}" && ./cmd.sh rm -f "${mod}"
    echo ""
    refresh_mods_running_file "${DIR}/mods.running"
    #[ -f mods.running ] && (cat mods.running | grep -vE "^${mod}\s.+$" > mods.running)
    #[ -f mods.running ] && [ -z "$(cat mods.running)" ] && rm -f mods.running
  done
else
  echo "=============================="
  echo "Stopping all services"
  echo "=============================="
  set -e
  ./cmd.sh down --remove-orphans
  echo ""
  refresh_mods_running_file "${DIR}/mods.running"
  #rm -f mods.running
  set +e
fi
