#!/usr/bin/env bash

##################################################
# Import functions
##################################################
source "$(dirname "$(readlink -f "$0")")/header.sh"
import _utils.sh
import _mod.sh
import _build.sh
import _domain-router.sh

##################################################
# Acutal execution
##################################################
set -e

[ ! -x "${WB_DIR}/prebuild.sh" ] && {
  echo "Script[${WB_DIR}/prebuild.sh] is invalid, cannot process succeeding step!" >&2
  exit 1
}
"${WB_DIR}/prebuild.sh"

mod::init

build::build dmrouter::build

set +e
