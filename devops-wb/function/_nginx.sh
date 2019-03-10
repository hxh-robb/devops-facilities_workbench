#!/usr/bin/env bash
##################################################
# Function for nginx project
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
#   nginx::tar_static_resources
##################################################
nginx::build(){
  set -e
  
  local tmp_app_file="/tmp/$(cat /proc/sys/kernel/random/uuid).tar.gz"
  local tar_out=$(tar -czv -f "${tmp_app_file}" *)
  echo "${tar_out}" >&2
  
  local mod_dir="${mod_dir:-"${PROJECT_DIR}"}"
  dist_dir="${mod_dir}"
  
  echo "${tmp_app_file}"
  
  set +e
}
