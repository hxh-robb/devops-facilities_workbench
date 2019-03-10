#!/usr/bin/env bash
##################################################
# [build.sh] step relative functions
##################################################
# Dependencies:
#   mod::init
##################################################
# Prerequisite env-var:
#   ${WB_DIR}
#   ${DIST_DIR}
#   ${PROJECT_DIR}
##################################################
# Function list:
#   build::build
##################################################

#====================================================================================================

##################################################
# Function:[build::build]
#
# Arguments:
#   $1 = ${build_func}, required;
#   $2 = ${mod_name}, optional;
#   $3 = ${mod_version}, optional;
#   $4 = ${mod_dir}, optional;
#   $5 = ${mod_wb_dir}, optional;
#   $6 = ${dist_dir}, optional;
##################################################
build::build(){
  
  [ ! $# -ge 1 ] && {
    echo "Function[build::build] requires at least [1] arguments:" >&2
    echo '$1 = <Function of build>' >&2
    echo "----- following are optional arguments -----" >&2
    echo '$2 = <Version of project/module>' >&2
    echo '$3 = <Version of project/module>' >&2
    echo '$4 = <Path to folder of project/module>' >&2
    echo '$5 = <Path to devops-wb folder of project/module>' >&2
    echo '$6 = <Path to distribution folder>' >&2
    return 1
  }
  
  ## $1
  local build_func=$1
  type -t "${build_func}" >/dev/null || {
    echo "Function[${build_func}] is invalid, cannot process succeeding step!" >&2
    return 1
  }
  
  ## $2
  local mod_name=${2:-"${mod_name}"}
  [ -z "${mod_name}" ] && {
    echo "Name is empty, cannot process succeeding step!" >&2
    return 1
  }
  
  ## $3
  local mod_version=${3:-"${mod_version}"}
  [ -z "${mod_version}" ] && {
    echo "Version is empty, cannot process succeeding step!" >&2
    return 1
  }
  
  ## $4
  local mod_dir=${4:-"${mod_dir}"}
  [ ! -d "${mod_dir}" ] && mod_dir=${PROJECT_DIR}
  [ ! -d "${mod_dir}" ] && {
    echo "Folder[${mod_dir}] not found, cannot process succeeding step!" >&2
    return 1
  }
  
  ## $5
  local mod_wb_dir=${5:-"${mod_wb_dir}"}
  [ ! -d "${mod_wb_dir}" ] && mod_wb_dir=${WB_DIR}
  [ ! -d "${mod_wb_dir}" ] && {
    echo "Folder[${mod_wb_dir}] not found, cannot process succeeding step!" >&2
    return 1
  }
  
  ## $6
  local dist_dir=${6:-"${dist_dir}"}
  [ ! -d "${dist_dir}" ] && dist_dir=${DIST_DIR}
  [ ! -d "${dist_dir}" ] && {
    echo "Folder[${dist_dir}] not found, cannot process succeeding step!" >&2
    return 1
  }

  #echo "========== debug =========="
  #echo "build_func=[${build_func:-$1}]"
  #echo "mod_name=[${mod_name:-$2}]"
  #echo "mod_version=[${mod_version:-$3}]"
  #echo "mod_dir=[${mod_dir:-$4}]"
  #echo "mod_wb_dir=[${mod_wb_dir:-$5}]"
  #echo "dist_dir=[${dist_dir:-$6}]"
  #echo "========== debug =========="
  #return 0
  
  ## pre-build
  #[ -x "${WB_DIR}"/prebuild.sh ] && "${WB_DIR}"/prebuild.sh
  
  ## check mod file
  local target_mod_file="${dist_dir}/${mod_name}.mod"
  [ ! -f "${DIST_DIR}/.mods" ] && {
    echo "File[${DIST_DIR}/.mods] not found, cannot process succeeding step!" >&2
    return 1
  }
  [ $(wc -l "${DIST_DIR}/.mods"|awk '{print $1}') -eq 1 ] && cp -f "${DIST_DIR}/.mods" "${target_mod_file}"
  [ $(wc -l "${DIST_DIR}/.mods"|awk '{print $1}') -gt 1 ] && grep "${mod_name}" "${DIST_DIR}/.mods" > "${target_mod_file}"
  [ ! $(wc -l "${target_mod_file}"|awk '{print $1}') -eq 1 ] && {
    echo "File[${target_mod_file}] is invalid, cannot process succeeding step!" >&2
    return 1
  }
  
  ## check Dockerfile
  [ ! -f "${mod_wb_dir}/Dockerfile" ] && {
    echo "File[${mod_wb_dir}/Dockerfile] not found, cannot process succeeding step!" >&2
    return 1
  }
  
  ## build application
  cd "${mod_dir}"

  local out_file=$("${build_func}") || {
    return 1
  }
  [ ! -f "${out_file}" ] && {
    echo "${out_file}"
    echo "Function[${build_func}] did not return a file result, cannot process succeeding step!" >&2
    return 1
  }
  
  local target_app_file="${dist_dir}/$(basename "${out_file}")"
  cp -f "${out_file}" "${target_app_file}"
  
  ## build docker image
  #echo "mod_file=[${target_mod_file}]"
  #echo "app_file=[${target_app_file}]"
  set -e

  cd "${dist_dir}"

  docker build -f "${mod_wb_dir}/Dockerfile" --build-arg app_file="$(basename "${target_app_file}")" --build-arg mod_file="$(basename "${target_mod_file}")" . -t "${mod_name}:${mod_version}" || {  
    rm -f "${target_app_file}"
    rm -f "${target_mod_file}"
    return 1
  }
  
  rm -f "${target_app_file}"
  rm -f "${target_mod_file}"

  set +e
}
