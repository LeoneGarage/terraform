#!/bin/bash

set -e

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. $DIR/utils.sh

WORKSPACE_NAME=
ACCOUNT_LEVEL=

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -w|--workspace)
      WORKSPACE_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    -al|--account-level)
      ACCOUNT_LEVEL="true"
      shift # past argument
      ;;
    *)    # unknown option
      echo "Unknown option $1"
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

ACCOUNT_NAME="$(grep databricks_account_name secrets.tfvars | cut -d'=' -f2 | tr -d '" ')---account---level"

if [ -z "$ACCOUNT_LEVEL" ] || [ "$ACCOUNT_LEVEL" != "true" ]; then
  if [ -z "$WORKSPACE_NAME" ]; then
  W=$(terraform -chdir=$DIR workspace show)
    if [ "$W" != "default" ] && [ "$W" != "$ACCOUNT_NAME" ]; then
      WORKSPACE_NAME=$W
    else
      if [ "$W" = "default" ]; then
        echo "Cannot destroy default workpace"
        echo "run terraform workspace select <workspace name> to change from default or specify -w <workspace name> argument"
        exit 1
      else
        if [ "$W" = "$ACCOUNT_NAME" ]; then
          echo "Cannot destroy $ACCOUNT_NAME workpace"
          echo "run terraform workspace select <workspace name> to change from default or specify -w <workspace name> argument"
          exit 1
        fi
      fi
    fi
  fi

  terraform -chdir=$DIR/workspace init
  if [ -n "$WORKSPACE_NAME" ] && workspace_exists "$DIR/workspace" "$WORKSPACE_NAME" && [ -n "$WORKSPACE_EXISTS_RETURN" ]; then
    terraform -chdir=$DIR/workspace workspace select $WORKSPACE_NAME
    terraform -chdir=$DIR/workspace destroy -auto-approve -var="workspace=$WORKSPACE_NAME"
    DESTROY_EXIT_CODE=$?
    if [ $DESTROY_EXIT_CODE = 0 ]; then
      terraform -chdir=$DIR/workspace workspace select default
      if [ -n "$WORKSPACE_NAME" ]; then
        terraform -chdir=$DIR/workspace workspace delete $WORKSPACE_NAME
      fi
    fi
  fi

  terraform -chdir=$DIR/provision init
  if [ -n "$WORKSPACE_NAME" ] && workspace_exists "$DIR/provision" "$WORKSPACE_NAME" && [ -n "$WORKSPACE_EXISTS_RETURN" ]; then
    terraform -chdir=$DIR/provision workspace select $WORKSPACE_NAME
    VARFILE="$(cd "$(dirname "secrets.tfvars")"; pwd)/$(basename "secrets.tfvars")"
    terraform -chdir=$DIR/provision destroy -auto-approve -var-file $VARFILE
    terraform -chdir=$DIR/provision workspace select default
    if [ -n "$WORKSPACE_NAME" ]; then
      terraform -chdir=$DIR/provision workspace delete $WORKSPACE_NAME
    fi
  fi
else
  if [ workspace_exists $DIR/provision/log-delivery $ACCOUNT_NAME ] && [ -n $WORKSPACE_EXISTS_RETURN ]; then
    terraform -chdir=$DIR/provision/log-delivery init
    terraform -chdir=$DIR/provision/log-delivery workspace select $ACCOUNT_NAME
    terraform -chdir=$DIR/provision/log-delivery destroy -auto-approve -var-file $VARFILE
    terraform -chdir=$DIR/provision/log-delivery workspace select default
    terraform -chdir=$DIR/provision/log-delivery workspace delete $ACCOUNT_NAME
  fi
fi


if [ -n "$WORKSPACE_NAME" ] && workspace_exists "$DIR" "$WORKSPACE_NAME" && [ -n "$WORKSPACE_EXISTS_RETURN" ]; then
  terraform -chdir=$DIR workspace select default
  terraform -chdir=$DIR workspace delete $WORKSPACE_NAME
fi