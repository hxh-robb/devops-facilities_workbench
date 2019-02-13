#!/usr/bin/env bash

export SCRIPT=$(readlink -f "$0")
export DIR=$(dirname "$SCRIPT")
cd "$DIR"

#set -e
#./setup-prereq.sh
#set +e

cmd=$(type -t docker) # check docker command exist
if [ $? == 1 ]; then
  >&2 echo "Prerequisite(Docker) is not installed yet! Please install docker."
  exit 1
fi
cmd=`type -t docker-compose` # check docker compose command exist
if [ $? == 1 ]; then
  >&2 echo "Prerequisite(Docker Compose) is not installed yet! Please install the docker-compose."
  exit 1
fi

cmd=`type -t timedatectl`
if [ $? == 0 ]; then
  echo `timedatectl|grep "Time zone"|awk '{print $3}'` > timezone
else
  touch timezone
fi

images=`docker images 2>&1` # check docker command is available
if [ $? == 1 ]; then
  >&2 echo "Permission denied! Please use \"su ${USER}\" to open a new session."
  exit 1
fi

for setting in `cat settings`; do
  if [ "${setting:0:1}" != "#" ]; then
    export $setting
  fi
done

if [ -n "$SME_LOG_DIR" ] && [ ! -d "$SME_LOG_DIR" ]; then
  mkdir -p "$SME_LOG_DIR" # wait for operator input password 2>/dev/null
  if [ $? != 0 ]; then
    echo "Log dir doesn't not exist, trying to \"mkdir -p [$SME_LOG_DIR]\"."
    sudo mkdir -p "$SME_LOG_DIR" # wait for operator input password
  fi
  if [ $? == 0 ]; then
    echo "Log dir is now created."
  else
    echo "Fail to create log dir."
    exit 1
  fi
fi

yamls=""
for yaml in $(ls deployment/*.yaml); do
   yamls="-f $yaml $yamls"
done
docker-compose $yamls config > docker-compose.yaml

starter_name=$(echo "$STARTER_TAG"|awk -F':' '{print $1}')
starter_version=$(echo "$STARTER_TAG"|awk -F':' '{print $2}')
options=" -p $starter_name"
docker-compose $options $@
