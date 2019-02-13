#!/usr/bin/env bash

export SCRIPT=$(readlink -f "$0")
export DIR=$(dirname "$SCRIPT")
cd "$DIR"

if [ $(./cmd.sh ps -q|wc -l) -gt 0 ]; then
  #./logs.sh $@
  echo "++++++++++++++++++++++++++++++ ps.sh ++++++++++++++++++++++++++++++"
  ./ps.sh $@
  echo "++++++++++++++++++++++++++++++ stats.sh ++++++++++++++++++++++++++++++"
  ./stats.sh $@
  echo "++++++++++++++++++++++++++++++ top.sh ++++++++++++++++++++++++++++++"
  ./top.sh $@
fi
