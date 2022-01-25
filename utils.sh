#!/bin/bash

workspace_exists() {
  WORKSPACE_EXISTS_RETURN=$(terraform -chdir=$1 workspace list | grep -w $2 | tr -d '* ')
  if [ "$WORKSPACE_EXISTS_RETURN" != "$2" ]; then
    WORKSPACE_EXISTS_RETURN=
  fi
}

workspace_create_if_not_exists() {
  local WORKSPACE_EXISTS=$(terraform -chdir=$1 workspace list | grep -w $2 | tr -d '* ')
  if [ "$WORKSPACE_EXISTS" != "$2" ]; then
    terraform -chdir=$1 workspace new $2
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
