#!/usr/bin/env bash

TS=$(date -u +%Y%m%d%H%M%S)
CMD=$(readlink -f "$0")
DIR=$(dirname "$CMD")
SRC="${DIR}/src"
DIST="${DIR}/dist"
cd "${DIR}"

####################################
## Parameters
#rm -rf "${DIST}" #TODO:git tag/skip docker push/etc ..

SKIP_DOCKER_PUSH=false
SKIP_UNCHANGED_MODS=false
MODS=""
for arg in $@; do
  [ "$arg" == "--skip-docker-push" ] && SKIP_DOCKER_PUSH=true && continue
  [ "$arg" == "--skip-unchanged-mods" ] && SKIP_UNCHANGED_MODS=true && continue
  [[ "$arg" == "--"* ]] && continue
  MODS="$MODS $arg"
done

## trim
MODS=${MODS%% }
MODS=${MODS## }
#echo "MODS = [${MODS}]"
#echo ""
####################################

## check [mods]
mkdir -p "${DIST}"
if [ ! -f "${DIST}/mods" ]; then
  touch "${DIST}/mods"
  SKIP_UNCHANGED_MOD=false
  MODS=""
fi

## starter tag
touch .name
touch .version
[ -s .name ] && \
  starter_name=$(cat .name|awk '{print tolower($0)}')  || \
  starter_name='app-starter'
[ -s .version ] && \
  starter_version=$(cat .version|awk '{print tolower($0)}')|| \
  starter_version='baseline'
starter_tag="${starter_name}:${starter_version}"

## starter scripts & underlying configurations
[ -n "$(ls "${SRC}"/*.sh 2>/dev/null)" ] && cp -f "${SRC}"/*.sh "${DIST}"
[ -d "${SRC}/config" ] && cp -rf "${SRC}"/config "${DIST}/"
[ -d "${SRC}/deployment" ] && cp -rf "${SRC}"/deployment "${DIST}/"

## starter [settings]
target_settings="${DIST}/settings"
echo "=============================="
echo "Initial [${target_settings}]"
echo "=============================="
if [ ! -f "${DIST}/settings" ]; then
  grep -vE "^\s*#.*" .settings > "${target_settings}"
else
  while read setting; do
    setting_key=$(echo "${setting}"|awk -F'=' '{print $1}')
    setting_val=$(echo "${setting}"|awk -F'=' '{print substr($0, index($0,$2))}')

    if [ $(grep -cE "^${setting_key}=.*" "${target_settings}") -eq 0 ]; then
      echo "Appending [${setting_key}]=[${setting_val}]"
      echo "${setting_key}=${setting_val}" >> "${target_settings}" 
    else
      echo "[${setting_key}] is listed in [${target_settings}] already!"
    fi
  done <<< "$(grep -vE "^\s*#.*$" .settings)"
  echo "$(cat "${target_settings}" | grep -vE "STARTER_TAG=.+")" > "${target_settings}"
  echo "------------------------------"
fi
echo "STARTER_TAG=${starter_tag}" >> "${target_settings}"
export $(grep -E "^REGISTRY=.+$" "${target_settings}")
cat "${target_settings}"
echo ""

## loop over the [modules/*] folders
t1=$(date +"%Y-%m-%d %H:%M:%S %z %:::z")

building_log=/tmp/$(cat /proc/sys/kernel/random/uuid)
built_images=/tmp/$(cat /proc/sys/kernel/random/uuid)

#touch "${building_log}"
#touch "${built_images}"

for mod_dir in modules/*; do
  grep -Fxq "${mod_dir}" .modignore && continue;
  
  [ ! -d "${mod_dir}/.devops-wb" ] && continue;
  [ ! -x "${mod_dir}/.devops-wb/mod.sh" ] && continue;
  [ ! -x "${mod_dir}/.devops-wb/prebuild.sh" ] && continue;
  [ ! -x "${mod_dir}/.devops-wb/build.sh" ] && continue;

  build_cmd="prebuild.sh"
  if [ -n "${MODS}" ]; then
    while read mod_info; do
      mod_name=$(echo "${mod_info}"|awk '{print $1}')
      mod_commit=$(echo "${mod_info}"|awk '{print $2}')

      if [ $(grep -cE "${mod_name}\s|${mod_name}$" <<< "${MODS}") -gt 0 ]; then
        build_cmd="build.sh"
        MODS="${MODS/${mod_name}/}"
        MODS=${MODS%% }
        MODS=${MODS## }
      fi
    done <<< "$("${mod_dir}"/.devops-wb/mod.sh)"
  elif [ "${SKIP_UNCHANGED_MODS}" == "true" ]; then
    while read mod_info; do
      if [ $(grep -cE "^${mod_info}$" "${DIST}/mods") -eq 0 ]; then
        build_cmd="build.sh"
        break;
      fi
    done <<< "$("${mod_dir}"/.devops-wb/mod.sh)"
  else
    build_cmd="build.sh"
  fi

  build_cmd="${mod_dir}/.devops-wb/${build_cmd}"
  if [ -f "${build_cmd}" ] && [ -x "${build_cmd}" ]; then
    echo "*************** [${mod_dir}] ***************"
    echo ""

    type tee >/dev/null 2>&1
    if [ $? == 1 ]; then
      "${build_cmd}" || exit 1
    else
      "${build_cmd}" | tee "${building_log}" || exit 1
      cat "${building_log}"|grep -E "^Successfully\stagged\s.+\:.+"|awk '{print $3}' >>"${built_images}" 
    fi

    ## starter [mods]
    if [ -s "${mod_dir}"/.devops-wb-dist/.mods ]; then
      echo "=============================="
      echo "Merging [.mods] to [mods]"
      echo "=============================="
      echo ".mods = [${mod_dir}/.devops-wb-dist/.mods]"
      echo "mods = [${DIST}/mods]"
      echo '------------------------------'
      
      while read mod_info; do
        mod_name=$(echo "${mod_info}"|awk '{print $1}')
        mod_commit=$(echo "${mod_info}"|awk '{print $2}')

        [ -z "${mod_name}" ] && echo "***** Invalid module name *****" && exit 1
        [ -z "${mod_commit}" ] && echo "***** Invalid commit hash *****" && exit 1

        if [ $(grep -cE "^${mod_name}\s.*$" "${DIST}/mods") -eq 0 ]; then
          echo "Appending:[${mod_info}]"
          echo "${mod_info}" >> "${DIST}/mods"
        elif \
          [ $(grep -cE "^${mod_name}\s.*$" "${DIST}/mods") -eq 1 ] && \
          [ $(grep -cE "^${mod_name}\s${mod_commit}$" "${DIST}/mods") -eq 0 ]; \
          then
          echo "Replacing:From [$(grep -oE "^${mod_name}\s.*$" "${DIST}/mods")] to [${mod_info}]"
          cat "${DIST}/mods" | grep -vE "^${mod_name}\s.*$" > "${DIST}/.mods"
          mv "${DIST}/.mods" "${DIST}/mods"
          echo "${mod_info}" >> "${DIST}/mods"
        elif [ $(grep -cE "^${mod_name}\s.*$" "${DIST}/mods") -gt 1 ]; then
          echo "***** Unexpected mods content *****"
          grep -E "^${mod_name}\s.*$" "${DIST}/mods"
          echo "***********************************"
          echo "Appending:[${mod_info}]"
          cat "${DIST}/mods" | grep -vE "^${mod_name}\s.*$" > "${DIST}/mods"
          echo "${mod_info}" >> "${DIST}/mods"
        else
          echo "Skip:[${mod_info}]:no changed!"
        fi
      done <<< "$(cat "${mod_dir}"/.devops-wb-dist/.mods)"
      
      echo '------------[mods]------------'
      cat "${DIST}/mods"
      echo ""
    fi

    ## starter [settings]
    if [ -s "${mod_dir}"/.devops-wb-dist/.settings ]; then
      echo "=============================="
      echo "Merging [.settings] to [settings]"
      echo "=============================="
      echo ".settings = [${mod_dir}/.devops-wb-dist/.settings]"
      echo "settings = [${DIST}/settings]"
      echo '------------------------------'
      
      while read setting; do
        setting_key=$(echo "${setting}"|awk -F'=' '{print $1}')
        setting_val=$(echo "${setting}"|awk -F'=' '{print substr($0, index($0,$2))}')
        if [ $(grep -cE "^${setting_key}=.*" "${DIST}/settings") -eq 0 ]; then
          echo "Appending [${setting_key}]=[${setting_val}]"
          echo "${setting_key}=${setting_val}" >> "${DIST}/settings" 
        else
          echo "[${setting_key}] is listed in [${DIST}/settings] already!"
        fi
      done <<< "$(grep -vE "^\s*#.*$" "${mod_dir}"/.devops-wb-dist/.settings)"
    
      echo '----------[settings]----------'
      cat "${DIST}/settings"
      echo ""
    fi

    ## starter [deployment/]
    [ -d "${mod_dir}"/.devops-wb-dist/deployment ] && \
      cp -rf  "${mod_dir}"/.devops-wb-dist/deployment "${DIST}/"

    ##starter [config/]
    [ -d "${mod_dir}"/.devops-wb-dist/config ] && \
      cp -rf  "${mod_dir}"/.devops-wb-dist/config "${DIST}/"
  else
    echo "*************** [${mod_dir}] ***************"
    echo "Skip [${mod_dir}]"
    echo ""
  fi
done

## build starter docker image
echo "=============================="
echo "Build docker image:[${starter_tag}]"
echo "=============================="
set -e
docker build . -t "${starter_tag}"
echo "${starter_tag}" >> "${built_images}"
set +e
echo ""

## docker tag & docker push
docker images --filter "dangling=false" --format "{{.Repository}}:{{.Tag}},{{.CreatedAt}}"|\
  while read image_info; do
    image_label="$(echo ${image_info}|awk -F',' '{print $1}')"
    t2=$(echo ${image_info}|awk -F',' '{print $2}')

    if [[ "${t2}" > "${t1}" ]]; then
      echo "=============================="
      echo "Post-build docker image:[${image_info}]"
      echo "=============================="
      
      if [ -f "${built_images}" ]; then
        [ $(grep -cE "^${image_label}$" "${built_images}") -eq 0 ] && continue
      fi
      
      if [ -n "${REGISTRY}" ]; then
        registry_image_label="${REGISTRY}${image_label}"
        docker tag "${image_label}" "${registry_image_label}"
        [ "${SKIP_DOCKER_PUSH}" == "false" ] && docker push "${registry_image_label}"
      fi

      echo ""
    fi
  done

rm -f "${building_log}"
rm -f "${built_images}"
