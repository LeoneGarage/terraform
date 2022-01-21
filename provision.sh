#!/bin/bash

set -e

pushd provision
CONFIGURE=(./configure.sh -vf secrets.tfvars) # initial command
CONFIGURE+=( $* )
"${CONFIGURE[@]}"
popd
