#!/usr/bin/env bash
##################################################
# Utility function
##################################################
# Dependencies:
#   <NONE>
##################################################
# Prerequisite env-var:
#   ${PROJECT_DIR}
##################################################
# Function list:
#   utils::identify_project_type: Initial necessary files and environment variable for [prebuild.sh]
##################################################

#====================================================================================================

##################################################
# Function:[utils::identify_project_type]
#
# Arguments:
#   $1 = ${mod_dir} # optional, given project path
# 
# Output:
#   "<type-1> <type-2> ... <type-n>"
##################################################
utils::identify_project_type(){
  #set -e
  local cur_dir=$(pwd)
  
  local mod_dir=${1:-${mod_dir}}
  [ ! -d "${mod_dir}" ] && mod_dir=${PROJECT_DIR}
  [ ! -d "${mod_dir}" ] && {
    echo "Folder[${mod_dir}] not found, cannot process succeeding step!" >&2
    return 1
  }
  
  set -e
  
  cd "${mod_dir}"
  local console_output=""
  if [ -f pom.xml ]; then
    console_output="${console_output} maven"
    
    if [ $(grep -B 10 "<executable>true" pom.xml|grep "org.springframework.boot"|wc -l) -gt 0 ]; then
      console_output="${console_output} springboot"
    fi
  fi
  
  if [ -f nginx.conf ]; then
    console_output="${console_output} nginx"
    
    if [ $(grep "\"/domain-router\":" nginx.conf|wc -l) -gt 0 ] || [ $(grep -E "^\s+server_name [^_]+;$" nginx.conf|wc -l) -gt 0 ]; then
      console_output="${console_output} domain-router"
    fi
    
    if [ -f package.json ] && [ $(grep "\"vue\":" package.json|wc -l) -gt 0 ]; then
      console_output="${console_output} vue"
    fi
  fi
 
  ## trim string
  console_output=($console_output)
  console_output=${console_output[@]}
  echo ${console_output}
  
  set +e
  
  cd "${cur_dir}"
  #set +e
}

#====================================================================================================
