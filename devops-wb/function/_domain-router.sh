#!/usr/bin/env bash
##################################################
# Function for domain router project
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
dmrouter::build(){
  set -e
  
  [ ! -d "servers" ] && {
    mkdir -p servers
  }
  
  local tmp_app_file="/tmp/$(cat /proc/sys/kernel/random/uuid).tar.gz"
  local tar_out=$(tar -czv -f "${tmp_app_file}" nginx.conf servers/)
  echo "${tar_out}" >&2
  
  echo "${tmp_app_file}"
  
  set +e
}
