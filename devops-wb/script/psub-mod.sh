#!/usr/bin/env bash

##################################################
# Import functions
##################################################
source "$(dirname "$(readlink -f "$0")")/header.sh"
import _mod.sh
import _parent-sub.sh

##################################################
# Acutal execution
##################################################
psub::iterate_subs mod::print_info
