#!/bin/bash

set -e

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

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ACCOUNT_NAME="$(grep databricks_account_name secrets.tfvars | cut -d'=' -f2 | tr -d '"')---account---level"

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
set +e
if [ -n "$WORKSPACE_NAME" ]; then
terraform -chdir=$DIR/workspace workspace select $WORKSPACE_NAME
fi
terraform -chdir=$DIR/workspace destroy -auto-approve -var="workspace=$WORKSPACE_NAME"
DESTROY_EXIT_CODE=$?
if [ $DESTROY_EXIT_CODE = 0 ]; then
terraform -chdir=$DIR/workspace workspace select default
if [ -n "$WORKSPACE_NAME" ]; then
terraform -chdir=$DIR/workspace workspace delete $WORKSPACE_NAME
fi
fi
set -e

terraform -chdir=$DIR/provision init
if [ -n "$WORKSPACE_NAME" ]; then
  terraform -chdir=$DIR/provision workspace select $WORKSPACE_NAME
fi
VARFILE="$(cd "$(dirname "secrets.tfvars")"; pwd)/$(basename "secrets.tfvars")"
terraform -chdir=$DIR/provision destroy -auto-approve -var-file $VARFILE
terraform -chdir=$DIR/provision workspace select default
if [ -n "$WORKSPACE_NAME" ]; then
  terraform -chdir=$DIR/provision workspace delete $WORKSPACE_NAME
PRIVATELINK_DNS_STATE_FILE=$WORKSPACE_NAME-private-dns.tfvars
PRIVATELINK_DNS_STATE_FILE="$(cd "$(dirname "$PRIVATELINK_DNS_STATE_FILE")"; pwd)/$(basename "$PRIVATELINK_DNS_STATE_FILE")"
rm -f "$PRIVATELINK_DNS_STATE_FILE"
fi

if [ -n "$ACCOUNT_LEVEL" ] && [ "$ACCOUNT_LEVEL" = "true" ]; then
  terraform -chdir=$DIR/provision/log-delivery init
  terraform -chdir=$DIR/provision/log-delivery workspace select $ACCOUNT_NAME
  terraform -chdir=$DIR/provision/log-delivery destroy -auto-approve -var-file $VARFILE
  terraform -chdir=$DIR/provision/log-delivery workspace select default
  terraform -chdir=$DIR/provision/log-delivery workspace delete $ACCOUNT_NAME
fi


if [ -n "$WORKSPACE_NAME" ]; then
terraform -chdir=$DIR workspace select default
terraform -chdir=$DIR workspace delete $WORKSPACE_NAME
fi