#!/usr/bin/env bash

SCRIPT=`readlink -f "$0"`
DIR=`dirname "$SCRIPT"`
cd "$DIR"

mkdir -p "$DIR"/modules

git submodule status


if [ -z "$1" ]; then
  echo "Please input the module to remove:"
  read MOD
else
  MOD="$1"
fi

# git submodule status
git submodule deinit -f modules/$MOD
git rm -f modules/$MOD
rm -rf .git/modules/modules/$MOD
test -d modules/$MOD && rm -rf modules/$MOD

mod_lowercase=$(echo "$MOD"|awk '{print tolower($0)}')
rm starter/deployment/$mod_lowercase.yaml
