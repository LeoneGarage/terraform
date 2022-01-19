#!/bin/bash

set -e

WORKSPACE_NAME=
IGW=

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -w|--workspace)
      WORKSPACE_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    -igw)
      IGW=true
      shift # past argument
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

pushd provision
CONFIGURE=(./configure.sh -vf secrets.tfvars) # initial command
if [ -n "$WORKSPACE_NAME" ]; then
CONFIGURE+=( -w $WORKSPACE_NAME )
fi
if [ -n "$IGW" ] && [ "$IGW" = "true" ]; then
CONFIGURE+=( -igw )
fi
"${CONFIGURE[@]}"
popd

pushd workspace
terraform init
terraform apply -auto-approve
popd
