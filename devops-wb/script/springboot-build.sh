#!/usr/bin/env bash

##################################################
# Import functions
##################################################
source "$(dirname "$(readlink -f "$0")")/header.sh"
import _utils.sh
import _maven.sh
import _mod.sh
import _build.sh
import _springboot.sh

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
maven::setup_mvnw

springboot_build(){
  maven::mvn_package
  springboot::list_executable_jar
}

build::build springboot_build

set +e
