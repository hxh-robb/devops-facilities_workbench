#!/usr/bin/env bash

CMD=$(readlink -f "$0")
CMD_DIR=$(dirname "${CMD}")
DIR=$(dirname "${CMD_DIR}")
cd "${DIR}"

## parameters
# TODO

mkdir -p .devops-wb-dist
touch .devops-wb/.cfg
touch .devops-wb/.settings
touch .devops-wb/.ports
touch .devops-wb/.paths
touch .devops-wb/.name
touch .devops-wb/.version

[ -s .devops-wb/.name ] && \
  mod_name=$(cat .devops-wb/.name)  || \
  mod_name=$(basename "${DIR}")
mod_name=$(echo "${mod_name}"|awk '{print tolower($0)}')

[ -s .devops-wb/.version ] && \
  mod_version=$(cat .devops-wb/.version)|| \
  mod_version='latest' #TODO
mod_version=$(echo "${mod_version}"|awk '{print tolower($0)}')

tmp_envvar="/tmp/$(cat /proc/sys/kernel/random/uuid)"
tmp_port="/tmp/$(cat /proc/sys/kernel/random/uuid)"
tmp_deployment="/tmp/$(cat /proc/sys/kernel/random/uuid)"

envvar_regex="\\$\\{(.+):(.+)\\}"
port_regex="(^.*[^a-zA-Z])*(port|PORT)([^a-zA-Z].*)*[0-9]{1,5}"

ports_placeholder='__$ports$__'
paths_placeholder='__$paths$__'
name_placeholder='__$name$__'
version_placeholder='__$version$__'

## loop over all the springboot configuration files(end with .properties/.yml/.yaml)
for mod_config in $(find . -regex '.+\.\(properties\|yml\|yaml\)' -not -path "./.mvn/*" -and -not -path "./target/*" -and -not -path "./.devops-wb*/*"); do
  ## Fetch port -> [Dockerfile(expose)]
  if [ $(grep -cE "${port_regex}" "${mod_config}") -gt 0 ]; then
    #echo "=============================="
    #echo "Found port in file[$mod_config]"
    #echo "=============================="
    grep -nE  "${port_regex}" "${mod_config}"|\
    while read match_line; do
      lnum=$(echo "${match_line}"|awk -F':' '{print $1}')
      content=$(echo "${match_line}"|awk -F':' '{print substr($0, index($0,$2))}')
      expose_port=$(echo "${content}"|grep -oE "[0-9]{1,5}")

      #echo "line = [${lnum}]"
      ##echo "content = [${content}]"
      #echo "port = [${expose_port}]"

      [ -n "${expose_port}" ] && echo "${expose_port}" >> "${tmp_port}"
    done
  fi

  ## Fetch env-var -> [<mod>.cfg]
  if [ $(grep -cE "${envvar_regex}" "${mod_config}") -gt 0 ]; then
    #echo "=============================="
    #echo "Found enironment variable in file[$mod_config]"
    #echo "=============================="
    grep -nE  "${envvar_regex}" "${mod_config}"|\
    while read match_line; do
      lnum=$(echo "${match_line}"|awk -F':' '{print $1}')
      content=$(echo "${match_line}"|awk -F':' '{print substr($0, index($0,$2))}')
      envvar=$(echo "${content}"|grep -oE "${envvar_regex}")
      envvar_key=$(echo "${envvar}"|awk -F'{|}|:' '{print $2}')
      envvar_val=$(echo "${envvar}"|awk -F'{|}|:' '{print substr($0,index($0,$3),length($0)-length($2)-4)}')

      #echo "line = [${lnum}]"
      ##echo "content = [${content}]"
      #echo "key = [${envvar_key}]"
      #echo "value = [${envvar_val}]"

      found_in_tmp=$(grep -c "${envvar_key}" "${tmp_envvar}" 2>/dev/null)
      if [ -z "${found_in_tmp}" ] || [ ${found_in_tmp} -eq 0 ]; then
        echo "${envvar_key}=${envvar_val}" >> "${tmp_envvar}"
      fi


    done
  fi

done

## [.devops-wb/Dockerfile]
dockerfile_tpl=".devops-wb/dockerfile.template"
target_dockerfile=".devops-wb/Dockerfile"
if [ -f "${tmp_port}" ] && [ -f "${dockerfile_tpl}" ]; then
  echo "=============================="
  echo "Generating [${target_dockerfile}]"
  echo "=============================="
  cat "${dockerfile_tpl}"|sed "s/${ports_placeholder}/$(cat "${tmp_port}")/g" > "${target_dockerfile}"
  cat "${target_dockerfile}"
  echo ""
fi

## [.devops-wb-dist/config/<mod>.cfg]
target_cfg=".devops-wb-dist/config/${mod_name}.cfg"
mkdir -p $(dirname ${target_cfg})
if [ -f "${tmp_envvar}" ]; then
  echo "=============================="
  echo "Generating [${target_cfg}]"
  echo "=============================="
  #mv -f "${tmp_envvar}" ${target_cfg}
  cp -f "${tmp_envvar}" ${target_cfg}
  cat ${target_cfg}
  echo ""
  
  ## Merging custom env-var
  if [ -s .devops-wb/.cfg ]; then
    [ ! -f "${target_cfg}" ] && touch "${target_cfg}"
    echo "=============================="
    echo "Merging [.cfg] to [${target_cfg}]"
    echo "=============================="
    echo '----------[.devops-wb/.cfg]----------'
    cat ".devops-wb/.cfg"
    echo "----------[before merging:${target_cfg}]----------"
    cat "${target_cfg}"
    echo '------------------------------'
    while read envvar; do
      envvar_key=$(echo "${envvar}"|awk -F'=' '{print $1}')
      envvar_val=$(echo "${envvar}"|awk -F'=' '{print substr($0, index($0,$2))}')
      if [ $(grep -cE "^${envvar_key}=.*" "${target_cfg}") -eq 0 ]; then
        echo "Appending [${envvar_key}]=[${envvar_val}]"
        echo "${envvar_key}=${envvar_val}" >> "${target_cfg}"
      else
        echo "Replacing [${envvar_key}]"
        echo "Old value = [$(grep -cE "^${envvar_key}=.*" "${target_cfg}"|awk -F'=' '{print substr($0, index($0,$2))}')]"
        echo "New value = [${envvar_val}]"
        echo "TODO:Replacing [${envvar_key}]"
        #echo "[${setting_key}] is listed in [${DIST}/settings] already!"
      fi
    done <<< "$(grep -vE "^\s*#.*$" ./devops-wb/.cfg)"
    echo "----------[after merging:${target_cfg}]----------"
    cat "${target_cfg}"
    echo ""
  fi
fi

## [.devops-wb-dist/deployment/<mod>.yaml]
deployment_tpl=".devops-wb/deployment.template"
custom_deployment=".devops-wb/deployment.yaml"
target_deployment=".devops-wb-dist/deployment/${mod_name}.yaml"
mkdir -p $(dirname ${target_deployment})
if [ -f "${custom_deployment}" ]; then
  echo "=============================="
  echo "Generating [${target_deployment}]"
  echo "=============================="
  cp -f "${custom_deployment}" "${target_deployment}"
  cat ${target_deployment}
  echo ""
elif [ -f "${deployment_tpl}" ]; then
  echo "=============================="
  echo "Generating [${target_deployment}]"
  echo "=============================="
  cp -f "${deployment_tpl}" "${target_deployment}"

  ## name & version
  sed -i "s/${name_placeholder}/${mod_name}/g" "${target_deployment}"
  sed -i "s/${version_placeholder}/${mod_version}/g" "${target_deployment}"

  ## ports
  cp /dev/null "${tmp_deployment}"
  if [ -s .devops-wb/.ports ]; then
    awk '{print "      - "$0}' .devops-wb/.ports > "${tmp_deployment}"
  fi
  ports_replacement="${tmp_deployment}"
  if [ -f ${ports_replacement} ]; then
    sed -i "/${ports_placeholder}/r ${ports_replacement}" "${target_deployment}"
  fi
  sed -i "/${ports_placeholder}/d" "${target_deployment}"
  
  ## paths
  cp /dev/null "${tmp_deployment}"
  if [ -s .devops-wb/.paths ]; then
    awk '{print "      - "$0}' .devops-wb/.paths > "${tmp_deployment}"
  fi
  paths_replacement="${tmp_deployment}"
  if [ -f "${paths_replacement}" ]; then
    sed -i "/${paths_placeholder}/r ${paths_replacement}" "${target_deployment}"
  fi
  sed -i "/${paths_placeholder}/d" "${target_deployment}"
 
  ## display final content
  cat ${target_deployment}
  echo ""
fi

## [.devops-wb-dist/.settings] # TODO:grep -vE "^\s*#.*"
if [ -f .devops-wb/.settings ]; then
  echo "=============================="
  echo "Generating [.devops-wb-dist/.settings]"
  echo "=============================="
  cp .devops-wb/.settings .devops-wb-dist/.settings
  cat .devops-wb-dist/.settings
  echo ""
fi

## [.devops-wb-dist/.mods]
if [ -x .devops-wb/mod.sh ]; then
  echo "=============================="
  echo "Generating [.devops-wb-dist/.mods]"
  echo "=============================="
  .devops-wb/mod.sh > .devops-wb-dist/.mods
  cat .devops-wb-dist/.mods
  echo ""
fi

rm -f ${tmp_envvar} ${tmp_port} ${tmp_deployment}
