#!/usr/bin/env bash
##################################################
# Function for springboot project
##################################################
# Dependencies:
#   ?_mod.sh
#   ?_prebuild.sh
##################################################
# Prerequisite env-var:
#   ${WB_DIR}
#   ${PROJECT_DIR}
##################################################
# Function list:
#   springboot::iterate_config_files: Iterate springboot config file(*.yaml/*.yml/*.properties)
#   springboot::scan_envvar: Search for env-var that appears in springboot config file
#   springboot::scan_port: Search for port that appears in springboot config file
#   springboot::fetch_envvars: springboot::iterate_config_files + springboot::scan_envvar + <remove duplicated item>
#   springboot::fetch_ports: springboot::iterate_config_files + springboot::scan_port + <remove duplicated item>
#   springboot::list_executable_jar
##################################################

#====================================================================================================

##################################################
# Function:[springboot::iterate_config_files]
#
# Arguments:
#   $1 = ${mod_dir} # optional, given project/module folder
#   $2 = ${mod_wb_dir} # optional, given devops-wb folder of project/module
#   $3 = ${func} # optional, given function to call that use the config file as argument
##################################################
springboot::iterate_config_files(){
  #set -e
  local cur_dir=$(pwd)
  
  ## $1
  local mod_dir=${1:-${mod_dir}}
  [ ! -d "${mod_dir}" ] && mod_dir=${PROJECT_DIR}
  [ ! -d "${mod_dir}" ] && {
    echo "Folder[${mod_dir}] not found, cannot process succeeding step!" >&2
    return 1
  }
  
  ## $2
  local ignore_devops_wb=()
  local mod_wb_dir=${2:-"${mod_wb_dir}"}
  [ ! -d "${mod_wb_dir}" ] && mod_wb_dir="${mod_dir}/$(basename "${WB_DIR}")"
  [ -d "${mod_wb_dir}" ] && {
    if [ "${mod_dir}" == "$(dirname "${mod_wb_dir}")" ]; then
      ignore_devops_wb=( -and -not -path "./$(basename "${mod_wb_dir}")*/*")
    fi
  }
  
  ## $3
  local func="$3"
  
  set -e
  cd "${mod_dir}"
  local springboot_file
  local filename_regex='.+\.\(properties\|yml\|yaml\)'
  for springboot_config_file in $(find . -regex "${filename_regex}" -not -path "./.mvn/*" -and -not -path "./target/*" "${ignore_devops_wb[@]}"); do
    type -t "${func}" >/dev/null && {
      "${func}" "${springboot_config_file}"
    }
  done
  set +e
  
  cd "${cur_dir}"
}

#====================================================================================================

##################################################
# Function:[springboot::scan_envvar]
#
# Arguments:
#   $1 = ${springboot_config_file}
##################################################
springboot::scan_envvar(){
  local springboot_config_file=$1
  [ ! -s ${springboot_config_file} ] && {
    echo "File[${springboot_config_file}] is not a vaild config file" >&2
    return 1
  }
  
  local envvar_regex="\\$\\{(.+):(.+)\\}"
  
  if [ $(grep -cE "${envvar_regex}" "${springboot_config_file}") -gt 0 ]; then
    #local lnum
    local match_line content envvar envvar_key envvar_val
    grep -nE  "${envvar_regex}" "${springboot_config_file}"|\
    while read match_line; do
      #lnum=$(echo "${match_line}"|awk -F':' '{print $1}')
      content=$(echo "${match_line}"|awk -F':' '{print substr($0, index($0,$2))}')
      envvar=$(echo "${content}"|grep -oE "${envvar_regex}")
      envvar_key=$(echo "${envvar}"|awk -F'{|}|:' '{print $2}')
      envvar_val=$(echo "${envvar}"|awk -F'{|}|:' '{print substr($0,index($0,$3),length($0)-length($2)-4)}')
      
      echo "${envvar_key}=${envvar_val}"
    done
  fi
}

#====================================================================================================

##################################################
# Function:[springboot::scan_port]
#
# Arguments:
#   $1 = ${springboot_config_file}
##################################################
springboot::scan_port(){
  local springboot_config_file=$1
  [ ! -s ${springboot_config_file} ] && {
    echo "File[${springboot_config_file}] is not a vaild config file" >&2
    return 1
  }
  
  port_regex="(^.*[^a-zA-Z])*(port|PORT)([^a-zA-Z].*)*[0-9]{1,5}"
  
  if [ $(grep -cE "${port_regex}" "${springboot_config_file}") -gt 0 ]; then
    #local lnum
    local match_line content port
    grep -nE  "${port_regex}" "${springboot_config_file}"|\
    while read match_line; do
      #lnum=$(echo "${match_line}"|awk -F':' '{print $1}')
      content=$(echo "${match_line}"|awk -F':' '{print substr($0, index($0,$2))}')
      port=$(echo "${content}"|grep -oE "[0-9]{1,5}")
      
      [ -n "${port}" ] && echo "${port}"
    done
  fi
}

#====================================================================================================

##################################################
# Function:[springboot::fetch_envvars]
#
# Arguments:
#   $1 = ${mod_dir} # optional, given project/module folder
#   $2 = ${mod_wb_dir} # optional, given devops-wb folder of project/module
##################################################
springboot::fetch_envvars(){
  set -e
  
  local envvar envvar_key nodup_size
  declare -A nodup
  declare -a nodup_in_order
  while read envvar; do
    [ -z "${envvar}" ] && continue
    envvar_key="$(echo "${envvar}"|awk -F'=' '{print $1}')"
    nodup_size=${#nodup[@]}
    nodup[${envvar_key}]=1
    [ ${nodup_size} -lt ${#nodup[@]} ] && {
      nodup_in_order=("${nodup_in_order[@]}" "${envvar}")
    }
  done <<< "$(springboot::iterate_config_files "$1" "$2" springboot::scan_envvar)"
  
  for envvar in "${nodup_in_order[@]}"; do
    echo "${envvar}"
  done
  
  set +e
}

#====================================================================================================

##################################################
# Function:[springboot::fetch_ports]
#
# Arguments:
#   $1 = ${mod_dir} # optional, given project/module folder
#   $2 = ${mod_wb_dir} # optional, given devops-wb folder of project/module
##################################################
springboot::fetch_ports(){
  set -e
  
  local port nodup_size
  declare -A nodup
  declare -a nodup_in_order
  while read port; do
    [ -z "${port}" ] && continue
    nodup_size=${#nodup[@]}
    nodup[${port}]=1
    [ ${nodup_size} -lt ${#nodup[@]} ] && {
      nodup_in_order=("${nodup_in_order[@]}" "${port}")
    }
  done <<< "$(springboot::iterate_config_files "$1" "$2" springboot::scan_port)"
  
  for port in "${nodup_in_order[@]}"; do
    echo "${port}"
  done
  
  set +e
}

#====================================================================================================

##################################################
# Function:[springboot::build]
#
# Arguments:
#   <NONE>
##################################################
springboot::list_executable_jar(){
  set -e
  echo "$(pwd)/$(find target -type f -perm /a+x -name *.jar -not -name maven-wrapper.jar|head -n 1)"
  set +e
}

#====================================================================================================
