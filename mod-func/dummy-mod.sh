#!/usr/bin/env bash

CMD=$(readlink -f "$0")
CMD_DIR=$(dirname "${CMD}")
DIR=$(dirname "${CMD_DIR}")
cd "${DIR}"

[ ! -e ".git" ] && echo "[${DIR}] is not a git repository!" >&2 && exit 1

## <mod name> <git commit hash>
echo "$(basename "${DIR}"|awk '{print tolower($0)}') $(git log --pretty="%H" -n 1)"
