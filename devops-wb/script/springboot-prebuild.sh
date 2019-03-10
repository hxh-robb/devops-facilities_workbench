#!/usr/bin/env bash

##################################################
# Import functions
##################################################
source "$(dirname "$(readlink -f "$0")")/header.sh"
import _utils.sh
import _mod.sh
import _prebuild.sh
import _springboot.sh

##################################################
# Acutal execution
##################################################
set -e

## Verify project type
mod_type=$(utils::identify_project_type)
[ $(grep 'springboot' <<< "${mod_type}"|wc -l) -eq 0 ] && {
  echo "[${PROJECT_DIR}] is not a springboot project!" >&2
  exit 1
}

## Init
mod::init

## Execute prebuild
prebuild::prebuild \
  "${mod_name}" "${mod_version}" \
  "${WB_DIR}" "${DIST_DIR}" \
  "$(springboot::fetch_envvars "${PROJECT_DIR}" "${WB_DIR}")" \
  "$(springboot::fetch_ports "${PROJECT_DIR}" "${WB_DIR}")" \
  "$(mod::print_info)"

set +e
