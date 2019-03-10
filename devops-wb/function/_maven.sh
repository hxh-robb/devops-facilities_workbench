#!/usr/bin/env bash
##################################################
# Function for maven project
##################################################
# Dependencies:
#   <NONE>
##################################################
# Prerequisite env-var:
#   ${PROJECT_DIR}
##################################################
# Function list:
#   maven::setup_mvnw
##################################################

#====================================================================================================

##################################################
# Function:[maven::setup_mvnw]
#
# Arguments:
#   $1 = ${mod_type} # optional, given project/module folder
##################################################
maven::setup_mvnw(){
  local cur_dir=$(pwd)
  [ -d "${PROJECT_DIR}" ] || return 0

  cd "${PROJECT_DIR}"

  ## $1
  local mod_type=${1:-"${mod_type}"}
  
  if [ $(grep 'maven' <<< "${mod_type}"|wc -l) -gt 0 ] && [ ! -x mvnw ]; then
    type mvn 2>/dev/null || {
      cd "${cur_dir}"
      echo "[maven] is not installed yet!"
      return 1
    }
    
    echo "=============================="
    echo "Setting up Maven Wrapper"
    echo "------------------------------"
    mvn -N io.takari:maven:wrapper
    [ -f .gitignore ] && {
      if [ $(grep '!.mvn/wrapper/maven-wrapper.jar' .gitignore |wc -l) -eq 0 ]; then
        echo "" >> .gitignore
        echo "## Maven Wrapper" >> .gitignore
        echo "!.mvn/wrapper/maven-wrapper.jar" >> .gitignore
      fi
    }
  fi
  
  cd "${cur_dir}"
}

#====================================================================================================

##################################################
# Function:[maven::mvn_package]
#
# Arguments:
#   <NONE>
##################################################
maven::mvn_package(){
  local mvn_cmd
  [ -x mvnw ] && mvn_cmd="./mvnw" || mvn_cmd="mvn"
  
  type -t "${mvn_cmd}" > /dev/null || {
    echo "Maven not found, cannot process succeeding step!" >&2
    return 1
  }
  
  set -e
  "${mvn_cmd}" -Dmaven.test.skip=true -D skipTests clean package >&2
  set +e
}

#====================================================================================================
