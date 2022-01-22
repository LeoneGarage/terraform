#!/bin/bash

set -e

PLAN=

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -plan)
      PLAN=true
      shift # past argument
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

pushd workspace
terraform init
if [ -n "$PLAN" ] && [ "$PLAN" = "true" ]; then
terraform plan
else
terraform apply -auto-approve
fi
popd
