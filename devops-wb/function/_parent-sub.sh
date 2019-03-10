#!/usr/bin/env bash
##################################################
# [parent-submodule] folder structure extension
##################################################
# Dependencies:
#   _mod.sh
##################################################
# Prerequisite env-var:
#   ${CMD}
#   ${WB_DIR}
#   ${DIST_DIR}
#   ${FUNC_DIR}
#   ${PROJECT_DIR}
##################################################
# Function list:
#   psub::init: Initial sub-module/sub-project files
#   psub::iterate_subs: Iterate sub-module/sub-project folders
##################################################

#====================================================================================================

##################################################
# Function:[psub::init]
#
# Arguments:
#   <NONE>
#
# Expected files:
#   ${WB_DIR}/.mod-wb-dir # optional
##################################################
psub::init(){
  local cur_dir=$(pwd)
  
  [ ! -d "${PROJECT_DIR}" ] && {
    echo "Folder[${PROJECT_DIR}] not found, cannot process succeeding step!" >&2
    return 1
  }
  
  touch "${WB_DIR}/.settings"
  touch "${WB_DIR}/.version"
  
  set -e
  if [ -s "${WB_DIR}/.mod-wb-dir" ]; then
    while read mod_wb_path; do
      ## ${mod_wb_dir}
      mod_wb_dir="${WB_DIR}/${mod_wb_path}"
      [ ! -d "${mod_wb_dir}" ] && {
        mkdir -p "${mod_wb_dir}"
      }
      
      ## ${mod_wb_dir}/.mod-dir
      mod_dir_file="${mod_wb_dir}/.mod-dir"
      [ ! -s "${mod_dir_file}" ] && {
        touch "${mod_dir_file}"
        basename "${mod_wb_dir}" > "${mod_dir_file}"
      }
      
      ## ${mod_wb_dir}/.version
      mod_version_file="${mod_wb_dir}/.version"
      if [ ! -s "${mod_version_file}" ] && [ -f "${WB_DIR}/.version" ]; then
        rm -f "${mod_version_file}"
        ln -s "${WB_DIR}/.version" "${mod_version_file}"
      elif [ ! -f "${mod_version_file}" ]; then
        touch "${mod_version_file}"
      fi
      
      ## ${mod_wb_dir}/.settings
      mod_settings_file="${mod_wb_dir}/.settings"
      if [ ! -f "${WB_DIR}/.settings" ]; then
        touch "${mod_settings_file}"
      else
        rm -f "${mod_settings_file}"
        ln -s "${WB_DIR}/.settings" "${mod_settings_file}"
      fi
      
    done < "${WB_DIR}/.mod-wb-dir"
  else
    touch "${WB_DIR}/.mod-wb-dir"
  fi
  set +e
}

#====================================================================================================

##################################################
# Function:[psub::iterate_subs]
#
# Arguments:
#   $1 = ${func} # required, given function to call in sub-project folder
#
# Expected files:
#   ${WB_DIR}/.mod-wb-dir # optional
##################################################
psub::iterate_subs(){
  local cur_dir=$(pwd)
  local mod_dir
  
  [ ! -d "${PROJECT_DIR}" ] && {
    echo "Folder[${PROJECT_DIR}] not found, cannot process succeeding step!" >&2
    return 1
  }
  
  type -t "$1" >/dev/null || {
    echo "Command[${1}] is not available, cannot process succeeding step!" >&2
    return 1
  }
  
  psub::init
  
  if [ -s "${WB_DIR}/.mod-wb-dir" ]; then
    while read mod_wb_path; do
      mod_wb_dir="${WB_DIR}/${mod_wb_path}"
      mod_dir_file="${mod_wb_dir}/.mod-dir"
      mod_dir="${PROJECT_DIR}/$(cat "${mod_dir_file}")"
      
      if [ ! -d "${mod_dir}" ]; then
        #echo "Folder[${mod_dir}] not found, ignore this module!" >&2
        continue
      fi
      
      cd "${mod_dir}"
      "$1"
    done < "${WB_DIR}/.mod-wb-dir"
  else
    "$1"
  fi
  
  cd "${cur_dir}"
}
