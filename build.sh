#!/usr/bin/env bash

## Build options:
## --no-docker-push
## --quick-build
## --prereq

NO_DOCKER_PUSH=false
QUICK_BUILD=false
NEED_PREREQ=false
PREREQ_ONLY=false

for arg in $@; do
  test "$arg" == "--no-docker-push" && NO_DOCKER_PUSH=true
  test "$arg" == "--quick-build" && QUICK_BUILD=true
  test "$arg" == "--prereq" && NEED_PREREQ=true
  test "$arg" == "--prereq-only" && PREREQ_ONLY=true
done

## cd to working directory

TS=`date -u +%Y%m%d%H%M%S`
CMD=`readlink -f "$0"`
DIR=`dirname "$CMD"`
cd "$DIR"

## Intermediate directories:
## (1) starter
## (2) prerequisites 
## (3) .out = (.tag) + (1) + (2)
## (4) .release = (3) + <tar>

STARTER_DIR="$DIR"/starter
PREREQ_DIR="$DIR"/prerequisites

OUT_DIR="$DIR"/.out
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

RELEASE_DIR="$DIR"/.release
mkdir -p "$RELEASE_DIR"

if [ "$PREREQ_ONLY" == "true" ]; then
  RELEASE_FILE="$RELEASE_DIR/starter-prereq.tar.gz" 
  cd "$DIR"/prerequisites
  tar -cvz -f "$RELEASE_FILE" *
  cd "$DIR"
  echo "Built release files:$RELEASE_FILE"
  exit 0
fi

if [ -f "$STARTER_DIR"/settings ]; then
  for setting in $(cat "$STARTER_DIR"/settings); do
    if [ "${setting:0:1}" != "#" ]; then
      export $setting
    fi
  done
fi

## Update modules
./update-modules.sh

## Copy starter configurations and shell scripts
cp -r "$STARTER_DIR"/* "$OUT_DIR/"

## Build modules
for mod_dir in modules/*
do
  test ! -d "$mod_dir" && continue
  
  mod_name=$(echo `basename "$mod_dir"`|awk '{print tolower($0)}')
  if grep -Fxq `echo "$mod_name"` .modignore
  then
    continue
  fi

  if [ -d "$mod_dir" ] && [ -f "$mod_dir/build.sh" ]; then
    if $QUICK_BUILD && [ -f "$mod_dir/.stamp" ]; then
      current_stamp=$(./stamp.sh "$mod_dir")
      last_stamp=$(cat "$mod_dir/.stamp")
      test "$current_stamp" == "$last_stamp" && echo "no change in $mod_dir" && continue
    fi
    
    echo "=============================== [$mod_name] ==============================="
    ## Build module docker images
    t1=`date +"%Y-%m-%d %H:%M:%S %z %:::z"`
    $mod_dir/build.sh || exit 1
    docker images --filter "dangling=false" --format "{{.Repository}}:{{.Tag}},{{.CreatedAt}}"|\
    while read image; do
      label="`echo $image|awk -F ',' '{print $1}'`"
      t2=`echo $image|awk -F ',' '{print $2}'`

      #if [[ "$t2" > "$t1" ]] && [[ "$label" == "$mod_name"* ]]; then
      if [[ "$t2" > "$t1" ]]; then
        ## push images
        if [ -n "$label" ] && [ -n "$REGISTRY" ]; then
          remote_label="$REGISTRY$label"
          echo "Pushing image[$label] to registry"
          docker tag "$label" "$remote_label"
          $NO_DOCKER_PUSH || docker push "$remote_label" && echo "[$remote_label] is now pushed to registry" || echo "Cannot push image[$label] to registry"
        fi
      fi
    done

    ## Copy module env-var configuration
    mkdir -p "$OUT_DIR/config"
    if [ -d "$mod_dir/.docker" ]; then
      if [ -f "$mod_dir/.docker/env" ]; then
        cp "$mod_dir/.docker/env" "$OUT_DIR/config/$mod_name.cfg"
      elif [ -n "$(ls "$mod_dir"/.docker/*.cfg 2>/dev/null)" ]; then
        cp "$mod_dir"/.docker/*.cfg "$OUT_DIR"/config/
      fi

      if [ -f "$mod_dir/.docker/deployment.yaml" ]; then
        cp "$mod_dir/.docker/deployment.yaml" "$OUT_DIR/deployment/$mod_name.yaml"
      fi

      if [ -f "$mod_dir/.docker/settings" ]; then
        for mod_setting in $(cat "$mod_dir/.docker/settings"); do
          if [ "${mod_setting:0:1}" != "#" ]; then
            test "$(grep -c "$mod_setting" "$OUT_DIR"/settings)" == "0" && echo "$mod_setting" >> "$OUT_DIR"/settings && export $mod_setting
          fi
        done
      fi
    fi

    ./stamp.sh "$mod_dir" --save
  fi
done

$NEED_PREREQ && cp -r "$PREREQ_DIR"/* "$OUT_DIR/"
starter_tag=$(cat .tag|awk '{print tolower($0)}')
starter_name=$(echo $starter_tag|awk -F ':' '{print $1}')
starter_version=$(echo $starter_tag|awk -F ':' '{print $2}')
echo "STARTER_TAG=$starter_tag" >> "$OUT_DIR"/settings

## Archive starter release file
RELEASE_FILE="$RELEASE_DIR/${starter_name}_${starter_version}.$TS.tar.gz" 
cd "$OUT_DIR"
tar -cvz -f "$RELEASE_FILE" *
cd "$DIR"
echo "Built release files:$RELEASE_FILE"

if [ -n "$REGISTRY" ]; then
  remote_starter_tag="${REGISTRY}${starter_tag}"
  docker build -f "$DIR/Dockerfile" "$DIR" -t "$remote_starter_tag"
  echo "Pushing image[$starter_tag] to registry"
  $NO_DOCKER_PUSH || (docker push "$remote_starter_tag" && echo "[$starter_tag] is now pushed to registry" || echo "Cannot push image[$starter_tag] to registry")
fi
