#!/usr/bin/env bash

export SCRIPT=$(readlink -f "$0")
export DIR=$(dirname "$SCRIPT")
cd "$DIR"

test -x dump.sh && ./dump.sh

echo "Stopping services"
./cmd.sh down 2>/dev/null
echo "Services are now stopped"
