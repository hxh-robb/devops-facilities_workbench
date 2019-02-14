#!/usr/bin/env bash

CMD=$(readlink -f "$0")
CMD_DIR=$(dirname "${CMD}")
DIR=$(dirname "${CMD_DIR}")
cd "${DIR}"

