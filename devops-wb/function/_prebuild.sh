#!/usr/bin/env bash
##################################################
# [prebuild.sh] step relative functions
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
#   prebuild::init: Initial necessary files and environment variable for [prebuild.sh]
#   prebuild::generate_dockerfile
#   prebuild::generate_mod_cfg
#   prebuild::generate_mod_yaml
#   prebuild::prebuild
##################################################

name_placeholder='__$name$__'
version_placeholder='__$version$__'
ports_placeholder='__$ports$__'
paths_placeholder='__$paths$__'

#====================================================================================================

##################################################
# Function:[prebuild::init]
#
# Arguments:
#   $1 = ${mod_wb_dir} # optional, given devops-wb folder of module/project
# 
# Touch files:
#   ${mod_wb_dir}/.cfg
#   ${mod_wb_dir}/.settings
#   ${mod_wb_dir}/.ports
#   ${mod_wb_dir}/.paths
##################################################
prebuild::init(){
  #set -e
  local cur_dir=$(pwd)
  
  local mod_wb_dir=${1:-"${mod_wb_dir}"}
  [ ! -d "${mod_wb_dir}" ] && mod_wb_dir=${WB_DIR}
  [ ! -d "${mod_wb_dir}" ] && {
    echo "Folder[${mod_wb_dir}] not found, cannot process succeeding step!" >&2
    return 1
  }
  
  ## ${mod_wb_dir}/.cfg
  local mod_cfg_file="${mod_wb_dir}/.cfg"
  [ ! -f "${mod_cfg_file}" ] && touch "${mod_cfg_file}"
  ## ${mod_wb_dir}/.settings
  local mod_settings_file="${mod_wb_dir}/.settings"
  [ ! -f "${mod_settings_file}" ] && touch "${mod_settings_file}"
  ## ${mod_wb_dir}/.ports
  local mod_ports_file="${mod_wb_dir}/.ports"
  [ ! -f "${mod_ports_file}" ] && touch "${mod_ports_file}"
  ## ${mod_wb_dir}/.paths
  local mod_paths_file="${mod_wb_dir}/.paths"
  [ ! -f "${mod_paths_file}" ] && touch "${mod_paths_file}"
  #set +e
}

#====================================================================================================

##################################################
# Function:[prebuild::generate_dockerfile]
#
# Arguments:
#   $1 = ${dockerfile_template}, required
#   $2 = ${target_path}, required
#   $3 = ${ports}, required; line based
##################################################
prebuild::generate_dockerfile(){
  [ ! $# -eq 3 ] && {
    echo "Function[prebuild::generate_dockerfile] requires exactly [3] arguments:" >&2
    echo '$1 = <Path to Dockerfile template>' >&2
    echo '$2 = <Path to Dockerfile>' >&2
    echo '$3 = <Exposed ports(line based)>' >&2
    return 1
  }
  
  ## $1
  local template_file=$1
  [ ! -f "${template_file}" ] && {
    echo "Template[${template_file}] not found, cannot process succeeding step!" >&2
    return 1
  }
  
  ## $2
  local target_path=$2
  mkdir -p "$(dirname "${target_path}")"

  ## $3
  local ports=($3)
  ports=${ports[@]}
  
  echo "=============================="
  echo "Generating [${target_path}]"
  echo "------------------------------"
  [ -z "${ports}" ] && {
    cat "${template_file}"|sed "/EXPOSE ${ports_placeholder}/d" > "${target_path}"
  } || {
    cat "${template_file}"|sed "s/${ports_placeholder}/${ports}/g" > "${target_path}"
  }
  [ -s "${target_path}" ] && cat "${target_path}" || echo "[${target_path}] is empty!"
}

#====================================================================================================

##################################################
# Function:[prebuild::generate_mod_cfg]
#
# Arguments:
#   $1 = ${target_path}, required
#   $2 = ${envvars}, required; line based
#   $3 = ${custom_envvar_file}, optional
##################################################
prebuild::generate_mod_cfg(){
  [ ! $# -ge 2 ] && {
    echo "Function[prebuild::generate_mod_cfg] requires at least [2] arguments:" >&2
    echo '$1 = <Path to cfg file>' >&2
    echo '$2 = <Environment variables(line based)>' >&2
    echo "----- following are optional arguments -----" >&2
    echo '$3 = <Path to custom envvar file>' >&2
    return 1
  }
  
  ## $1
  local target_path=$1
  mkdir -p "$(dirname "${target_path}")"

  ## $2
  local envvars="$2"
  
  ## $3
  local custom_envvar_file=$3
  
  echo "=============================="
  echo "Generating [${target_path}]"
  echo "------------------------------"
  [ -n "${envvars}" ] && echo "${envvars}" > "${target_path}" || touch "${target_path}"
  [ -s "${target_path}" ] && cat "${target_path}" || echo "[${target_path}] is empty!"
  
  if [ -s "${custom_envvar_file}" ]; then
    [ ! -f "${target_path}" ] && touch "${target_path}"
    echo "=============================="
    echo "Merging [${custom_envvar_file}] to [${target_path}]"
    echo "------------------------------"
    echo "[${custom_envvar_file}] content:"
    cat "${custom_envvar_file}"
    echo "------------------------------"
    local custom_envvar envvar_key envvar_val
    while read custom_envvar; do
      envvar_key=$(echo "${custom_envvar}"|awk -F'=' '{print $1}')
      envvar_val=$(echo "${custom_envvar}"|awk -F'=' '{print substr($0, index($0,$2))}')
      if [ $(grep -cE "^${envvar_key}=.*" "${target_path}") -eq 0 ]; then
        echo "Appending [${custom_envvar}]"
        echo "${custom_envvar}" >> "${target_path}"
      else
        echo "Replacing [${envvar_key}]"
        echo "Old line = [$(grep -E "^${envvar_key}=.*" "${target_path}")]"
        echo "New line = [${custom_envvar}]"
        cat "${target_path}"|grep -v "${envvar_key}=" > "${target_path}.tmp"
        mv "${target_path}.tmp" "${target_path}"
        echo "${custom_envvar}" >> "${target_path}"
      fi
    done <<< "$(grep -vE "^\s*#.*$" "${custom_envvar_file}")"
    echo "------------------------------"
    [ -s "${target_path}" ] && cat "${target_path}" || echo "[${target_path}] is empty!"
  fi
}

#====================================================================================================

##################################################
# Function:[prebuild::generate_mod_yaml]
#
# Arguments:
#   $1 = ${deployment_template}, required
#   $2 = ${target_path}, required
#   $3 = ${mod_name}, required
#   $4 = ${mod_version}, required
#   $5 = ${custom_ports_file}, optional
#   $6 = ${custom_paths_file}, optional
##################################################
prebuild::generate_mod_yaml(){
  [ ! $# -ge 4 ] && {
    echo "Function[prebuild::generate_mod_yaml] requires at least [4] arguments:" >&2
    echo '$1 = <Path to deployment configuration template>' >&2
    echo '$2 = <Path to actual deployment config file>' >&2
    echo '$3 = <Name of project/module>' >&2
    echo '$4 = <Version of project/module>' >&2
    echo "----- following are optional arguments -----" >&2
    echo '$5 = <Path to custom ports snippet file>' >&2
    echo '$6 = <Path to custom paths snippet file>' >&2
    return 1
  }
  
  ## $1
  local template_file=$1
  [ ! -f "${template_file}" ] && {
    echo "Template[${template_file}] not found, cannot process succeeding step!" >&2
    return 1
  }
  
  ## $2
  local target_path=$2
  mkdir -p "$(dirname "${target_path}")"
  
  ## $3
  local mod_name=${3:-"${mod_name}"}
  [ -z "${mod_name}" ] && {
    echo "Name[${template_file}] is invalid, cannot process succeeding step!" >&2
    return 1
  }
  
  ## $4
  local mod_version=${4:-"${mod_version}"}
  [ -z "${mod_version}" ] && {
    echo "Version[${mod_version}] is invalid, cannot process succeeding step!" >&2
    return 1
  }
  
  ## $5
  local ports_file=$5
  
  ## $6
  local paths_file=$6
  
  local tmp_file="/tmp/$(cat /proc/sys/kernel/random/uuid)"
  if [ -f "${template_file}" ]; then
    echo "=============================="
    echo "Generating [${target_path}]"
    echo "------------------------------"
    cp -f "${template_file}" "${target_path}"
    
    ## name & version
    sed -i "s/${name_placeholder}/${mod_name}/g" "${target_path}"
    sed -i "s/${version_placeholder}/${mod_version}/g" "${target_path}"
    
    ## ports
    [ -s "${ports_file}" ] && {
      awk '{print "      - "$0}' "${ports_file}" > "${tmp_file}"
      sed -i "/${ports_placeholder}/r ${tmp_file}" "${target_path}"
    } || {
      sed -i "s/ports:/ports: []/g" "${target_path}"
    }
    sed -i "/${ports_placeholder}/d" "${target_path}"
    
    ## paths
    [ -s "${paths_file}" ] && {
      awk '{print "      - "$0}' "${paths_file}" > "${tmp_file}"
      sed -i "/${paths_placeholder}/r ${tmp_file}" "${target_path}"
    }
    sed -i "/${paths_placeholder}/d" "${target_path}"
  fi
  [ -f "${tmp_file}" ] && rm -f "${tmp_file}"
  [ -s "${target_path}" ] && cat "${target_path}" || echo "[${target_path}] is empty!"
}

#====================================================================================================

##################################################
# Function:[prebuild::prebuild]
#
# Arguments:
#   $1 = ${mod_name}, required; for generating Dockerfile
#   $2 = ${mod_version}, required; for generating Dockerfile
#   $3 = ${mod_wb_dir}, required; for generating Dockerfile,${mod_name}.cfg,${mod_name}.yaml
#   $4 = ${dist_dir}, required; for generating ${mod_name}.cfg,${mod_name}.yaml
#   $5 = ${envvars}, optional; for generating ${mod_name}.cfg
#   $6 = ${ports}, optional; for generating Dockerfile
#   $7 = ${mod_info}, optional; for generating .mods
#
# Required files:
#   ${mod_wb_dir}/dockerfile.template, for generating Dockerfile
#   ${mod_wb_dir}/deployment.template, for generating ${mod_name}.yaml
#
# Optional files:
#   ${mod_wb_dir}/.cfg, for generating ${mod_name}.cfg
#   ${mod_wb_dir}/.ports, for generating ${mod_name}.yaml
#   ${mod_wb_dir}/.paths, for generating ${mod_name}.yaml
#   ${mod_wb_dir}/.settings
#
# Output files:
#   ${mod_wb_dir}/Dockerfile
#   ${dist_dir}/config/${mod_name}.cfg
#   ${dist_dir}/deployment/${mod_name}.yaml
#   ${dist_dir}/.settings
#   ${dist_dir}/.mods
##################################################
prebuild::prebuild(){
  [ ! $# -ge 4 ] && {
    echo "Function[prebuild::prebuild] requires at least [4] arguments:" >&2
    echo '$1 = <Name of project/module>' >&2
    echo '$2 = <Version of project/module>' >&2
    echo '$3 = <Path to devops-wb folder of project/module>' >&2
    echo '$4 = <Path to distribution folder>' >&2
    echo "----- following are optional arguments -----" >&2
    echo '$5 = <Environment variables(line based)>' >&2
    echo '$6 = <Exposed ports(line based)>' >&2
    echo '$7 = <Git commit record of project/module>' >&2
    return 1
  }
  
  ## $1
  local mod_name=${1:-"${mod_name}"}
  [ -z "${mod_name}" ] && {
    echo "Name is empty, cannot process succeeding step!" >&2
    return 1
  }
  
  ## $2
  local mod_version=${2:-"${mod_version}"}
  [ -z "${mod_version}" ] && {
    echo "Version is empty, cannot process succeeding step!" >&2
    return 1
  }
  
  ## $3
  local mod_wb_dir=${3:-"${mod_wb_dir}"}
  [ ! -d "${mod_wb_dir}" ] && {
    echo "Folder[${mod_wb_dir}] not found, cannot process succeeding step!" >&2
    return 1
  }
  #[ ! -s "${mod_wb_dir}/dockerfile.template" ] && {
  #  echo "Template[${mod_wb_dir}/dockerfile.template] is invalid, cannot process succeeding step!" >&2
  #}
  #[ ! -s "${mod_wb_dir}/deployment.template" ] && {
  #  echo "Template[${mod_wb_dir}/deployment.template] is invalid, cannot process succeeding step!" >&2
  #}
  
  ## $4
  local dist_dir=${4:-"${dist_dir}"}
  [ ! -d "${dist_dir}" ] && dist_dir="${DIST_DIR}"
  [ ! -d "${dist_dir}" ] && {
    echo "Folder[${dist_dir}] not found, cannot process succeeding step!" >&2
    return 1
  }
  
  ## $5
  local envvars_to_mod_cfg="$5"
  
  ## $6
  local ports_to_dockerfile="$6"
  
  ## $7
  local to_dot_mods="$7"
  
  ## Generate [${mod_wb_dir}/Dockerfile]
  [ -s "${mod_wb_dir}/dockerfile.template" ] && {
    prebuild::generate_dockerfile \
      "${mod_wb_dir}/dockerfile.template" \
      "${mod_wb_dir}/Dockerfile" \
      "${ports_to_dockerfile}"
    echo ""
  }

  ## Generate [${dist_dir}/config/${mod_name}.cfg]
  prebuild::generate_mod_cfg \
    "${dist_dir}/config/${mod_name}.cfg" \
    "${envvars_to_mod_cfg}" \
    "${mod_wb_dir}/.cfg"
  echo ""

  ## Generate [${dist_dir}/deployment/${mod_name}.yaml]
  [ -s "${mod_wb_dir}/deployment.template" ] && {
    prebuild::generate_mod_yaml \
      "${mod_wb_dir}/deployment.template" \
      "${dist_dir}/deployment/${mod_name}.yaml" \
      "${mod_name}" "${mod_version}" \
      "${mod_wb_dir}/.ports" \
      "${mod_wb_dir}/.paths"
    echo ""
  }
  
  ## Generate [${dist_dir}/.mods]
  target_path="${dist_dir}/.mods"
  echo "=============================="
  echo "Generating [${target_path}]"
  echo "------------------------------"
  [ -n "${to_dot_mods}" ] && {
    echo "${to_dot_mods}" > "${target_path}"
  } || {
    touch "${target_path}"
  }
  [ -s "${target_path}" ] && cat "${target_path}" || echo "[${target_path}] is empty!"
  echo ""
  
  ## Generate [${dist_dir}/.settings]
  target_path="${dist_dir}/.settings"
  echo "=============================="
  echo "Generating [${target_path}]"
  echo "------------------------------"
  [ -f "${mod_wb_dir}/.settings" ] && {
    cp "${mod_wb_dir}/.settings" "${target_path}"
  } || {
    touch "${target_path}"
  }
  [ -s "${target_path}" ] && cat "${target_path}" || echo "[${target_path}] is empty!"
  echo ""
}

#====================================================================================================
