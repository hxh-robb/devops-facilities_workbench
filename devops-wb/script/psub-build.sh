#!/usr/bin/env bash

##################################################
# Import functions
##################################################
source "$(dirname "$(readlink -f "$0")")/header.sh"
import _utils.sh
import _parent-sub.sh
import _mod.sh
import _build.sh
import _maven.sh
import _springboot.sh
import _vue.sh
import _domain-router.sh
import _nginx.sh

##################################################
# Acutal execution
##################################################
set -e

## prebuild
[ ! -x "${WB_DIR}/prebuild.sh" ] && {
  echo "Script[${WB_DIR}/prebuild.sh] is invalid, cannot process succeeding step!" >&2
  exit 1
}
"${WB_DIR}/prebuild.sh"

## build
mod_type=$(utils::identify_project_type)
if [[ "${mod_type}" == *"maven"* ]]; then
  cd "${PROJECT_DIR}"
  maven::setup_mvnw
  maven::mvn_package
fi

mods_info_exclusions=""
mod_build(){
  mod::init
  local mod_type=$(utils::identify_project_type)
  
  local mod_build_cmd
  local mods_info="$(psub::iterate_subs mod::print_info)"
  if [[ "${mod_type}" == *"springboot"* ]]; then
    mod_build_cmd=springboot::list_executable_jar
  elif [[ "${mod_type}" == *"vue"* ]]; then
    mod_build_cmd=vue::build
  elif [[ "${mod_type}" == *"domain-router"* ]]; then
    mod_build_cmd=dmrouter::build
  elif [[ "${mod_type}" == *"nginx"* ]]; then
    mod_build_cmd=nginx::build
  elif [[ "${mod_dir}" == "${mod_wb_dir}" ]]; then
    return 0 # no need to build
  else
    echo "==============================" >&2
    echo "Unable to identify project type, ignore building!" >&2
    echo "mod_type=[${mod_type}]" >&2
    echo "mod_name=[${mod_name}]" >&2
    echo "mod_version=[${mod_version}]" >&2
    echo "mod_dir=[${mod_dir}]" >&2
    echo "mod_wb_dir=[${mod_wb_dir}]" >&2
    echo "==============================" >&2
    echo "" >&2
    return 1
  fi
  
  for exclusion in ${mods_info_exclusions}; do
    mods_info="$(grep -v "${exclusion} " <<< "${mods_info}")"
  done
  
  build::build "${mod_build_cmd}"
}
psub::iterate_subs mod_build
unset mods_info_exclusions

set +e
