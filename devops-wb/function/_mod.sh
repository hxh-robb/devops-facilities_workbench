#!/usr/bin/env bash
##################################################
# [mod.sh] step relative functions
##################################################
# Dependencies:
#   <NONE>
##################################################
# Prerequisite env-var:
#   ${CMD}
#   ${WB_DIR}
#   ${DIST_DIR}
#   ${FUNC_DIR}
#   ${PROJECT_DIR}
##################################################
# Function list:
#   mod::init: Initial necessary files and environment variable for [mod.sh]
#   mod::print_info: Print module information
##################################################

#====================================================================================================

##################################################
# Function:[mod::init]
#
# Arguments:
#   $1 = ${mod_wb_dir} # optional, given devops-wb folder of module/project
#
# Expected files:
#   ${mod_wb_dir}/.name  # optional, touch if not exists
#   ${mod_wb_dir}/.version  # optional, touch if not exists
# 
# Touch files:
#   ${mod_wb_dir}/.name
#   ${mod_wb_dir}/.version
# 
# Changed global env-var:
#   ${mod_name}
#   ${mod_version}
##################################################
mod::init(){
  #set -e
  local cur_dir=$(pwd)
  
  local mod_wb_dir=${1:-"${mod_wb_dir}"}
  [ ! -d "${mod_wb_dir}" ] && mod_wb_dir=${WB_DIR}
  [ ! -d "${mod_wb_dir}" ] && {
    echo "Folder[${mod_wb_dir}] not found, cannot process succeeding step!" >&2
    return 1
  }

  ## ${mod_wb_dir}/.name
  local mod_name_file="${mod_wb_dir}/.name"
  [ ! -f "${mod_name_file}" ] && touch "${mod_name_file}"
  
  ## ${mod_wb_dir}/.version
  local mod_version_file="${mod_wb_dir}/.version"
  [ ! -f "${mod_version_file}" ] && touch "${mod_version_file}"
  
  ## init ${mod_name}
  if [ -s "${mod_wb_dir}/.name" ]; then
    mod_name=$(cat "${mod_wb_dir}/.name")
  else
    local mod_dir=${mod_dir}
    [ ! -d "${mod_dir}" ] && mod_dir=${PROJECT_DIR}
    mod_name=$(basename "${mod_dir}")
  fi
  mod_name=$(echo "${mod_name}"|awk '{print tolower($0)}')
  echo "${mod_name}" > "${mod_name_file}"
  
  ## init ${mod_version}
  if [ -s "${mod_wb_dir}/.version" ]; then
    mod_version=$(cat "${mod_wb_dir}/.version")
  else
    mod_version='latest'
  fi
  mod_version=$(echo "${mod_version}"|awk '{print tolower($0)}')
  #set +e
}

#====================================================================================================

##################################################
# Function:[mod::print_info]
#
# Arguments:
#   $1 = ${mod_dir} # optional, given project path
#
# Expected files:
#   ${mod_dir}/.git  # required
# 
# Output:
#   "<mod name> <git commit hash>"
##################################################
mod::print_info(){
  #set -e
  local cur_dir=$(pwd)
  
  local mod_dir=${1:-${mod_dir}}
  [ ! -d "${mod_dir}" ] && mod_dir=${PROJECT_DIR}
  [ ! -d "${mod_dir}" ] && {
    echo "Folder[${mod_dir}] not found, cannot process succeeding step!" >&2
    return 1
  }
  
  cd "${mod_dir}"
  
  set -e
  mod::init
  echo "${mod_name} $(git log --pretty="%H" -n 1)"
  set +e
  
  cd "${cur_dir}"
  #set +e
}

#====================================================================================================

mod::mod(){
  mod::print_info
}
