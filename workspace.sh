#!/bin/bash

set -e

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

WORKSPACE_NAME=
PLAN=

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -plan)
      PLAN=true
      shift # past argument
      ;;
    -w|--workspace)
      WORKSPACE_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

$DIR/configure_tf_workspace.sh $WORKSPACE_NAME

terraform -chdir=$DIR/workspace init
set +e
terraform -chdir=$DIR/workspace workspace new $WORKSPACE_NAME
set -e
terraform -chdir=$DIR/workspace workspace select $WORKSPACE_NAME
if [ -n "$PLAN" ] && [ "$PLAN" = "true" ]; then
terraform -chdir=$DIR/workspace plan -var="workspace=$WORKSPACE_NAME"
else
terraform -chdir=$DIR/workspace apply -auto-approve -var="workspace=$WORKSPACE_NAME"
fi
