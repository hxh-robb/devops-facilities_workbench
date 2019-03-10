#!/usr/bin/env bash

##################################################
# Import functions
##################################################
source "$(dirname "$(readlink -f "$0")")/header.sh"
import _mod.sh
import _prebuild.sh

##################################################
# Acutal execution
##################################################
set -e

## Init
mod::init

## Execute prebuild
prebuild::prebuild \
  "${mod_name}" "${mod_version}" \
  "${WB_DIR}" "${DIST_DIR}" \
  "" "" "$(mod::print_info)"

set +e
