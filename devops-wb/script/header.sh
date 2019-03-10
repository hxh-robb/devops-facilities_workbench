#!/usr/bin/env bash

##################################################
# Significant paths
##################################################
CMD=$(readlink -f "$0")
WB_DIR=$(dirname "${CMD}")
PROJECT_DIR=$(dirname "${WB_DIR}")
FUNC_DIR="${WB_DIR}/devops-wb-function"

#echo "=================================================="
#echo "CMD=[${CMD}]"
#echo "WB_DIR=[${WB_DIR}]"
#echo "DIST_DIR=[${DIST_DIR}]"
#echo "FUNC_DIR=[${FUNC_DIR}]"
#echo "PROJECT_DIR=[${PROJECT_DIR}]"
#echo "=================================================="

DIST_DIR="${WB_DIR}-dist"
mkdir -p "${DIST_DIR}"

import(){
  [ -f "${FUNC_DIR}/$1" ] && {
    source "${FUNC_DIR}/$1"
  } || {
    echo "Script[${FUNC_DIR}/$1] not found, cannot process succeeding step!"
  }
}
