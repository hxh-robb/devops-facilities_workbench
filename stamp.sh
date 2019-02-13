#!/usr/bin/env bash

test $# -lt 1 && exit 0;

save=false
for arg in $@
do
  test "$arg" == "--save" && save=true
done

SCRIPT=`readlink -f "$0"`
DIR=`dirname "$SCRIPT"`
cd "$DIR"

test ! -d "$1" && exit 0;
test ! -e "$1/.git" && exit 0;

cd "$1";

mod=$(git log|head -n 1|awk '{print $2}')
#test -n "$stamp" && echo "$stamp" > ".stamp"

submod=$(git submodule foreach "git log|head -n 1|awk '{print \$2}'")
#test -n "$submod_stamp" && echo "$submod_stamp" > ".submod_stamp"

stamp=$(echo "$mod";echo "$submod")
$save && echo "$stamp" > ".stamp" || echo "$stamp"
