#!/usr/bin/env bash

CMD=$(readlink -f "$0")
DIR=$(dirname "$CMD")
cd "${DIR}"

if [ ! -x mod-list.sh ]; then
  echo "[mod-list.sh] is missing, cannot verify parameters!"
  exit 1
fi

for mod in "$@" ; do
  mod=$(echo "$mod"|awk '{print tolower($0)}')
  ## Check if given module is exist or not
  if [ ! $(./mod-list.sh --name-only|grep "${mod}"|wc -l) -eq 1 ]; then
    echo "=============================="
    echo "module[${mod}] is not exists"
    echo "=============================="
    continue
  fi

  #echo "TODO:delete [${mod}]"
  #continue

  echo "===== Deleting [${mod}] ====="
  git submodule deinit -f modules/${mod}
  git rm -f modules/${mod}
  rm -rf .git/modules/modules/"${mod}"
  test -d modules/${mod} && rm -rf modules/${mod}
  test -f dist/deployment/${mod}.yaml && rm dist/deployment/${mod}.yaml
  echo "===== [${mod}] is now deleted ====="
done
