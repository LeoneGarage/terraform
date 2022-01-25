#!/bin/bash

set -e

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. $DIR/utils.sh

WORKSPACE_NAME=$1

CURR_W=$(terraform -chdir=$DIR workspace show)
if [ -z "$WORKSPACE_NAME" ]; then
  if [ "$CURR_W" != "default" ]; then
    WORKSPACE_NAME=$CURR_W
  fi
fi
if [ -z "$WORKSPACE_NAME" ]; then
RANDSTR=$(openssl rand -base64 12 | cut -c1-6 | sed 's/[^a-zA-Z0-9]//g')
WORKSPACE_NAME="terratest-$RANDSTR"
fi

if [ "$WORKSPACE_NAME" != "$CURR_W" ]; then
workspace_create_if_not_exists $DIR $WORKSPACE_NAME
terraform -chdir=$DIR workspace select $WORKSPACE_NAME
fi
