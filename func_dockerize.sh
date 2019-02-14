#!/usr/bin/env bash

dockerize(){
  mod_dir="$1"
  ([ -z "${mod_dir}" ] || [ ! -d "${mod_dir}" ] )&& echo "Invalid path!" >&2 && exit 1
}
