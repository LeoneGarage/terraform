#!/bin/bash

workspace_exists() {
  local ACCOUNT_NAME=$2
  local WORKSPACE_NAME=$3
  local TF_WORKSPACE_NAME=$ACCOUNT_NAME
  if [ -n "$WORKSPACE_NAME" ]; then
    local TF_WORKSPACE_NAME+="-"$WORKSPACE_NAME
  fi
  WORKSPACE_EXISTS_RETURN=$(terraform -chdir=$1 workspace list | grep -w "$TF_WORKSPACE_NAME$" | tr -d '* ')
  if [ "$WORKSPACE_EXISTS_RETURN" != "$TF_WORKSPACE_NAME" ]; then
    WORKSPACE_EXISTS_RETURN=
  fi
}

workspace_create_if_not_exists() {
  if ! workspace_exists $1 $2 $3 || [ -z "$WORKSPACE_EXISTS_RETURN" ]; then
    local ACCOUNT_NAME=$2
    local WORKSPACE_NAME=$3
    local TF_WORKSPACE_NAME=$ACCOUNT_NAME
    if [ -n "$WORKSPACE_NAME" ]; then
      local TF_WORKSPACE_NAME+="-"$WORKSPACE_NAME
    fi
    terraform -chdir=$1 workspace new $TF_WORKSPACE_NAME
  fi
}

workspace_state_get() {
  local ESCAPED_STR=$(printf "%q" $2)
  local STATE_EXISTS=$(terraform -chdir=$1 state list | grep -w $ESCAPED_STR | tr -d ' ')
  WORKSPACE_STATE_GET_RETURN=
  if [ -n "$STATE_EXISTS" ]; then
    WORKSPACE_STATE_GET_RETURN=$(terraform -chdir=$1 state show $2 | grep $3 | cut -d'=' -f2 | tr -d '" ')
  fi
}

workspace_select() {
  local ACCOUNT_NAME=$2
  local WORKSPACE_NAME=$3
  local TF_WORKSPACE_NAME=$ACCOUNT_NAME
  if [ -n "$WORKSPACE_NAME" ]; then
    local TF_WORKSPACE_NAME+="-"$WORKSPACE_NAME
  fi
  terraform -chdir=$1 workspace select $TF_WORKSPACE_NAME
}

workspace_delete() {
  local ACCOUNT_NAME=$2
  local WORKSPACE_NAME=$3
  local TF_WORKSPACE_NAME=$ACCOUNT_NAME
  if [ -n "$WORKSPACE_NAME" ]; then
    local TF_WORKSPACE_NAME+="-"$WORKSPACE_NAME
  fi
  terraform -chdir=$1 workspace delete $TF_WORKSPACE_NAME
}
