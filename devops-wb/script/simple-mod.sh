#!/usr/bin/env bash

##################################################
# Import functions
##################################################
source "$(dirname "$(readlink -f "$0")")/header.sh"
import _mod.sh

##################################################
# Acutal execution
##################################################
mod::mod
