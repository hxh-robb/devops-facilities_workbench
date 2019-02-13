#!/usr/bin/env bash

export SCRIPT=$(readlink -f "$0")
export DIR=$(dirname "$SCRIPT")
cd "$DIR"

./stop.sh 2>/dev/null

echo "Starting services"
set -e
./cmd.sh up --no-color -d --remove-orphans
set +e
echo "Services are now started"
