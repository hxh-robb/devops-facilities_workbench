#!/usr/bin/env bash
##################################################
# Function for vue project
##################################################
# Dependencies:
#   ? - mod::init
##################################################
# Prerequisite env-var:
#   ${WB_DIR}
#   ${DIST_DIR}
#   ${PROJECT_DIR}
##################################################
# Function list:
#   vue::build
##################################################

#====================================================================================================

##################################################
# Function:[maven::mvn_package]
#
# Arguments:
#   <NONE>
##################################################
vue::build(){
  type -t npm > /dev/null || {
    echo "Node Package Manager not found, cannot process succeeding step!" >&2
    return 1
  }
  
  set -e
  
  local npm_install_out="$(npm install)"
  echo "${npm_install_out}" >&2
  local npm_build_out="$(npm run build)"
  echo "${npm_build_out}" >&2
  [ ! -d "dist" ] && {
    echo "Folder[$(pwd)/dist] not found, cannot process succeeding step!" >&2
    return 1
  }
  [ ! -f "nginx.conf" ] && {
    echo "Folder[$(pwd)/nginx.conf] not found, cannot process succeeding step!" >&2
    return 1
  }
  cp -f nginx.conf dist/
  
  local cur_dir="$(pwd)"
  local tmp_app_file="/tmp/$(cat /proc/sys/kernel/random/uuid).tar.gz"
  cd "dist"
  local tar_dist_out=$(tar -czv -f "${tmp_app_file}" *)
  echo "${tar_dist_out}" >&2
  cd "${cur_dir}"
  
  echo "${tmp_app_file}"
  
  set +e
}

#====================================================================================================
