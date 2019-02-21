#!/usr/bin/env bash

NO_PROMPT=false
for arg in $@; do
  [ "$arg" == "--no-prompt" ] && NO_PROMPT=true
done

prompt(){
  [ "${NO_PROMPT}" == "false" ] && echo "$@"
}

refresh_mods_file(){
  param=("$@")
  [ -f "${param[0]}" ] && mods_file="${param[0]}" || mods_file="./mods"
  mods_history="$(dirname "${mods_file}")/mods_history"

  prompt "=============================="
  prompt "Refreshing mods file:[${mods_file}]"
  prompt "=============================="

  TS="$(date -u +%Y%m%d%H%M%S)"
  mkdir -p "${mods_history}" 
  [ -f "${mods_file}" ] && mv -f "${mods_file}" "${mods_history}/$(basename "${mods_file}").${TS}"
  cp /dev/null "${mods_file}"
  if [ -x ./cmd.sh ]; then
    while read service; do
      ./cmd.sh run --rm ${service} cat /app/mod 2>/dev/null >> "${mods_file}"
    done<<< "$(./cmd.sh ps --services 2>/dev/null)"
  fi
  
  prompt "$(cat "${mods_file}")"
  prompt ""
}

refresh_mods_running_file(){
  param=("$@")
  [ -f "${param[0]}" ] && mods_running_file="${param[0]}" || mods_running_file="./mods.running"
  mods_history="$(dirname "${mods_running_file}")/mods_history"

  prompt "=============================="
  prompt "Refreshing mods running file:[${mods_running_file}]"
  prompt "=============================="
  cp /dev/null "${mods_running_file}"
  if [ -x ./cmd.sh ]; then
    while read container_id; do
      [ -z "${container_id}" ] && continue
      container_name="$(docker ps --filter id=${container_id} --format {{.Names}})"
      echo "$(docker exec ${container_id} cat /app/mod) ${container_name}" >> "${mods_running_file}"
    done <<< "$(./cmd.sh ps -q 2>/dev/null)"
  fi
  
  prompt "$(cat "${mods_running_file}")"
  [ ! -s "${mods_running_file}" ] && rm -f "${mods_running_file}" || prompt ""
}

## MODS
prompt "=============================="
prompt "Fetching MODS from arguments:[$@]"
prompt "=============================="
MODS=""
for arg in $@; do
  [[ "$arg" == "--"* ]] && continue
  if [ "${arg}" == "ALL" ]; then
    empty_is_all=true
    MODS=""
    break
  elif [ "${arg}" == "UPDATED" ]; then
    empty_is_all=true
    MODS=""
    if [ -f "mods.running" ] && [ -f "mods" ]; then
      while read mod_info; do
        mod_name="$(echo "${mod_info}"|awk '{print $1}')"
        mod_commit="$(echo "${mod_info}"|awk '{print $2}')"

        mod_running_info="$(grep -E "^${mod_name}\s.+" mods.running)"
        [ -z "${mod_running_info}" ] && continue
        mod_running_commit="$(echo "${mod_running_info}"|awk '{print $2}')"
        [ "${mod_commit}" != "${mod_running_commit}" ] && MODS="${mod_name} ${MODS}"
      done < "mods"
    fi
    break
  else
    empty_is_all=false
    if [ $(./cmd.sh ps --services 2>/dev/null|grep -c "${arg}") -eq 0 ]; then
      prompt "WARNING:Invalid service:[${arg}]" >&2 
    else
      MODS="${arg} ${MODS}"
    fi
  fi
done

MODS="${MODS%% }"
MODS="${MODS## }"
[ "${empty_is_all}" == "false" ] && [ -z "${MODS}" ] && MODS="NONE"
prompt "${MODS:-ALL}"
prompt ""
