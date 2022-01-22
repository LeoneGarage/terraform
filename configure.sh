#!/bin/bash

set -e

PLAN=

SAVED=("$@")
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

./provision.sh -vf secrets.tfvars "${SAVED[@]}"

if [ -n "$PLAN" ] && [ "$PLAN" = "true" ]; then
./workspace.sh -plan
else
./workspace.sh
fi
