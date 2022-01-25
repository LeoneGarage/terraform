#!/bin/bash

set -e

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. $DIR/utils.sh

ACCOUNT_NAME=$1
WORKSPACE_NAME=$2

CURR_W=$(terraform -chdir=$DIR workspace show)
if [ -z "$WORKSPACE_NAME" ]; then
  if [ "$CURR_W" != "default" ]; then
    TF_WORKSPACE_NAME=$CURR_W
    WORKSPACE_NAME=${TF_WORKSPACE_NAME#"$ACCOUNT_NAME-"}
  fi
fi
if [ -z "$WORKSPACE_NAME" ]; then
  RANDSTR=$(openssl rand -base64 12 | cut -c1-6 | sed 's/[^a-zA-Z0-9]//g')
  WORKSPACE_NAME="terratest-$RANDSTR"
fi

if [ "$WORKSPACE_NAME" = "." ]; then
  WORKSPACE_NAME=
fi

if [ "$WORKSPACE_NAME" != "${CURR_W#"$ACCOUNT_NAME-"}" ]; then
  workspace_create_if_not_exists $DIR $ACCOUNT_NAME $WORKSPACE_NAME
  workspace_select "$DIR" $ACCOUNT_NAME $WORKSPACE_NAME
fi
