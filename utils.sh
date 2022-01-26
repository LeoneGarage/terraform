#!/bin/bash

workspace_exists() {
  local ACCOUNT_NAME=$2
  local WORKSPACE_NAME=$3
  local TF_WORKSPACE_NAME=$ACCOUNT_NAME
  if [ -n "$WORKSPACE_NAME" ]; then
    local TF_WORKSPACE_NAME+="-"$WORKSPACE_NAME
  fi
  WORKSPACE_EXISTS_RETURN=$(terraform -chdir=$1 workspace list | tr -d '* ' | grep -w "^$TF_WORKSPACE_NAME$")
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
  echo "Selected $TF_WORKSPACE_NAME terraform workspace in $1"
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

workspace_get_active_workspace() {
  local DIR=$1
  local ACCOUNT_NAME=$2
  local WORKSPACE_NAME=$3
  WORKSPACE_GET_ACTIVE_WORKSPACE_RETURN=$WORKSPACE_NAME
  if [ -z "$WORKSPACE_NAME" ]; then
    local W=$(terraform -chdir=$DIR workspace show)
    if [ "$W" != "default" ] && [ "$W" != "$ACCOUNT_NAME" ]; then
      local TF_WORKSPACE_NAME=$W
      WORKSPACE_NAME=${TF_WORKSPACE_NAME#"$ACCOUNT_NAME-"}
      WORKSPACE_GET_ACTIVE_WORKSPACE_RETURN=$WORKSPACE_NAME
    else
      if [ "$W" = "default" ]; then
        echo "Cannot destroy default workpace"
        echo "run terraform workspace select <workspace name> to change from default or specify -w <workspace name> argument"
        return 1
      else
        if [ "$W" = "$ACCOUNT_NAME" ]; then
          echo "Cannot destroy $ACCOUNT_NAME workpace"
          echo "run terraform workspace select <workspace name> to change from default or specify -w <workspace name> argument"
          return 2
        fi
      fi
    fi
  fi
}

workspace_destroy() {
  local DIR=$1
  shift
  local ACCOUNT_NAME=$1
  shift
  local WORKSPACE_NAME=$1
  shift
  local APPEND_WORKSPACE_VAR=$1
  shift
  if workspace_get_active_workspace "$DIR" $ACCOUNT_NAME $WORKSPACE_NAME ; then
    local WORKSPACE_NAME=$WORKSPACE_GET_ACTIVE_WORKSPACE_RETURN
    terraform -chdir=$DIR init
    if [ -n "$WORKSPACE_NAME" ] && workspace_exists "$DIR" $ACCOUNT_NAME $WORKSPACE_NAME && [ -n "$WORKSPACE_EXISTS_RETURN" ]; then
      workspace_select "$DIR" $ACCOUNT_NAME $WORKSPACE_NAME
      if [ -z "$APPEND_WORKSPACE_VAR" ] || [ "$APPEND_WORKSPACE_VAR" != "true" ]; then
        terraform -chdir=$DIR destroy -auto-approve $@
      else
        terraform -chdir=$DIR destroy -auto-approve -var="workspace=$ACCOUNT_NAME-$WORKSPACE_NAME" $@
      fi
      terraform -chdir=$DIR workspace select default
      if [ -n "$WORKSPACE_NAME" ]; then
        workspace_delete "$DIR" $ACCOUNT_NAME $WORKSPACE_NAME
      fi
    fi
  fi
}

workspace_account_destroy() {
  local DIR=$1
  shift
  local ACCOUNT_NAME=$1
  shift

  if workspace_exists "$DIR" $ACCOUNT_NAME && [ -n "$WORKSPACE_EXISTS_RETURN" ]; then
    terraform -chdir=$DIR init
    workspace_select "$DIR" $ACCOUNT_NAME
    terraform -chdir=$DIR destroy -auto-approve $@
    terraform -chdir=$DIR workspace select default
    workspace_delete "$DIR" $ACCOUNT_NAME
  fi
}

ACCOUNT_NAME="$(grep databricks_account_name secrets.tfvars | cut -d'=' -f2 | tr -d '" ')"
