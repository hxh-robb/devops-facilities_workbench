#!/usr/bin/env bash

CMD=$(readlink -f "$0")
DIR=$(dirname "$CMD")
cd "${DIR}"

[ ! -x "mod-list.sh" ] && echo "[mod-list.sh] is missing, cannot perform module dockerizing!" && exit 1

##############################
## Import Functions
##############################
[ ! -f "func_dockerize.sh" ] && echo "[func_dockerize.sh] is missing, cannot perform module dockerizing!" && exit 1
source ./func_dockerize.sh

##############################
## Parameters
##############################
# TODO

if [ $# -eq 0 ]; then
  mods=$(./mod-list.sh --name-only)
else
  mods="$@"
fi

for mod in ${mods}; do
  echo ${mod}
done
