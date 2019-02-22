#!/usr/bin/env bash

TS=$(date -u +%Y%m%d%H%M%S)
CMD=$(readlink -f "$0")
DIR=$(dirname "$CMD")
SRC="${DIR}/src"
DIST="${DIR}/dist"
cd "${DIR}"

[ -x mod-update.sh ] && ./mod-update.sh

mkdir -p "${DIST}"
touch "${DIST}/mods"

for mod_dir in modules/*; do
  grep -Fxq "${mod_dir}" .modignore && continue;
  
  [ ! -d "${mod_dir}/.devops-wb" ] && continue;
  [ ! -x "${mod_dir}/.devops-wb/mod.sh" ] && continue;

  build_cmd="${mod_dir}/.devops-wb/mod.sh"
  if [ -f "${build_cmd}" ] && [ -x "${build_cmd}" ]; then
    echo "*************** [${mod_dir}] ***************"
    echo ""

    "${build_cmd}" || exit 1

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
          cat "${DIST}/mods" | grep -vE "^${mod_name}\s.*$" > "${DIST}/mods"
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
  else
    echo "*************** [${mod_dir}] ***************"
    echo "Skip [${mod_dir}]"
    echo ""
  fi
done
