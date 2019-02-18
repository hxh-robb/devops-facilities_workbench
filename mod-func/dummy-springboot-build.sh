#!/usr/bin/env bash

CMD=$(readlink -f "$0")
CMD_DIR=$(dirname "${CMD}")
DIR=$(dirname "${CMD_DIR}")
DIST="${DIR}"/.devops-wb-dist
cd "${DIR}"

## Parameter
#TODO:git pull & git tag

touch .devops-wb/.name
touch .devops-wb/.version

[ -s .devops-wb/.name ] && \
  mod_name=$(cat .devops-wb/.name)  || \
  mod_name=$(basename "${DIR}")
mod_name=$(echo "${mod_name}"|awk '{print tolower($0)}')

[ -s .devops-wb/.version ] && \
  mod_version=$(cat .devops-wb/.version)|| \
  mod_version='latest'
mod_version=$(echo "${mod_version}"|awk '{print tolower($0)}')

#echo "*************** [${mod_name}] ***************"
#echo ""

## Pre-Build
[ -x "${CMD_DIR}"/prebuild.sh ] && "${CMD_DIR}"/prebuild.sh

## Build
set -e

target_jar=".devops-wb-dist/${mod_name}.jar"
#rm -f "${target_jar}"

./mvnw -Dmaven.test.skip=true -D skipTests clean package
echo ""

find . -type f -perm /a+x -name *.jar \
  -not -name maven-wrapper.jar -and -not -path "./.devops-wb-dist/*" \
  -exec cp -f {} "${target_jar}"  \;
docker build -f "${CMD_DIR}/Dockerfile" --build-arg app_file="${target_jar}" . -t "${mod_name}:${mod_version}"

[ "${mod_version}" != "latest" ] && docker tag "${mod_name}:${mod_version}" "${mod_name}:latest-release"
echo "latest" > .devops-wb/.version
rm -f "${target_jar}"

echo ""

set +e
