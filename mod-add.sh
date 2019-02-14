#!/usr/bin/env bash

for arg in $@; do
  if [[ "$arg" != --* ]]; then
    if [ -z "$git_url" ]; then
      git_url="$arg"
    elif [ -z "$git_branch" ]; then
      git_branch="$arg"
    fi
  fi
done

CMD=$(readlink -f "$0")
DIR=$(dirname "$CMD")
cd "${DIR}"

mkdir -p modules
echo "==========================="

test -z "${git_url}" && echo "Please input the git repo address:" || echo "git repo address:[${git_url}]"
test -z "${git_url}" && read git_url

mod=$(echo "${git_url}"|awk -F':|\/|\.git' '{print tolower($(NF-1))}')
test -d modules/${mod} && echo "[${mod}] is already exists" && exit 1

test -z "${git_branch}" && echo "Please input the branch to checkout:" || echo "git branch:[${git_branch}]"
test -z "${git_branch}" && read git_branch
echo "==========================="

git submodule add -b ${git_branch} ${git_url} modules/${mod}
echo "==========================="

test -x ./dockerize.sh && ./dockerize.sh modules/${mod}
