#!/usr/bin/env bash

##################################################
# Import functions
##################################################
source "$(dirname "$(readlink -f "$0")")/header.sh"
import _utils.sh
import _parent-sub.sh
import _mod.sh
import _prebuild.sh
import _springboot.sh

##################################################
# Acutal execution
##################################################
set -e

## Init
psub::init

mods_info_exclusions=""
mod_prebuild(){
  mod::init
  prebuild::init
  mod_type=$(utils::identify_project_type)
  
  local mod_envvars mod_ports
  local mods_info="$(psub::iterate_subs mod::print_info)"
  if [[ "${mod_type}" == *"springboot"* ]]; then
    mod_envvars="$(springboot::fetch_envvars "${mod_dir}" "${mod_wb_dir}")"
    mod_ports="$(springboot::fetch_ports "${mod_dir}" "${mod_wb_dir}")"
  elif [[ "${mod_type}" == *"nginx"* ]]; then
    mod_envvars=""
    mod_ports=""
  elif [[ "${mod_dir}" == "${mod_wb_dir}" ]]; then
    mods_info_exclusions="${mods_info_exclusions} ${mod_name}"
  else
    echo "==============================" >&2
    echo "Unable to identify project type, ignore prebuilding!" >&2
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
  
  ## Execute prebuild
  prebuild::prebuild \
    "${mod_name}" "${mod_version}" \
    "${mod_wb_dir}" "${DIST_DIR}" \
    "${mod_envvars}" "${mod_ports}" \
    "${mods_info}"
}
psub::iterate_subs mod_prebuild
unset mods_info_exclusions

set +e
