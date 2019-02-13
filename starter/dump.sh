#!/usr/bin/env bash

export SCRIPT=$(readlink -f "$0")
export DIR=$(dirname "$SCRIPT")
cd "$DIR"

[ $# -gt 0 ] && MOD=".$#-mods" || MOD=""

if [ $(./cmd.sh ps -q|wc -l) -gt 0 ]; then
  echo "Dumping services"
  TS="$(date -u +%Y%m%d%H%M%S)"

  LOG="$TS.log"
  ./logs.sh $@ > $LOG

  TOP="$TS.top"
  ./top.sh $@ > $TOP

  PS="$TS.ps"
  ./ps.sh $@ > $PS

  STATS="$TS.stats"
  ./stats.sh $@ > $STATS

  TAR="dump${MOD}.${TS}.tar.gz"
  tar -czv -f $TAR $LOG $TOP $PS $STATS

  rm -f *.log
  rm -f *.top
  rm -f *.stats
  rm -f *.ps
fi
