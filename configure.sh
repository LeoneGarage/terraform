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
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

pushd provision
./configure.sh -vf secrets.tfvars -w $WORKSPACE_NAME
popd

pushd workspace
terraform init
terraform apply  -auto-approve
popd
