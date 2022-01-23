#!/bin/bash

set -e

WORKSPACE_NAME=
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -w|--workspace)
      WORKSPACE_NAME="$2"
      shift # past argument
      shift # past value
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

if [ -z "$WORKSPACE_NAME" ]; then
W=$(terraform -chdir=$DIR workspace show)
  if [ "$W" != "default" ]; then
    WORKSPACE_NAME=$W
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
fi

if [ -n "$WORKSPACE_NAME" ]; then
terraform -chdir=$DIR workspace select default
terraform -chdir=$DIR workspace delete $WORKSPACE_NAME
fi