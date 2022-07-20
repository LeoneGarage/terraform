#!/bin/bash

set -e

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. $DIR/utils.sh

WORKSPACE_NAME=
ACCOUNT_LEVEL=
DESTROY_WORKSPACE_CONTENT_ONLY=
REGION=

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -w|--workspace)
      WORKSPACE_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    -wco|--workpace-content-only)
      DESTROY_WORKSPACE_CONTENT_ONLY="true"
      shift # past argument
      ;;
    -al|--account-level)
      ACCOUNT_LEVEL="true"
      shift # past argument
      ;;
    -r|--region)
      REGION="$2"
      shift # past argument
      shift # past value
      ;;
    *)    # unknown option
      echo "Unknown option $1"
      exit 1
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

VARFILE="$(cd "$(dirname "secrets.tfvars")"; pwd)/$(basename "secrets.tfvars")"

ARGS=()
if [ -n "$REGION" ]; then
  ARGS+=( -var="region=$REGION")
fi

if [ -z "$ACCOUNT_LEVEL" ] || [ "$ACCOUNT_LEVEL" != "true" ]; then
  workspace_destroy "$DIR/workspace" $ACCOUNT_NAME "$WORKSPACE_NAME" true $ARGS
  if [ -z "$DESTROY_WORKSPACE_CONTENT_ONLY" ] || [ "$DESTROY_WORKSPACE_CONTENT_ONLY" != "true" ]; then
    workspace_destroy "$DIR/provision" $ACCOUNT_NAME "$WORKSPACE_NAME" false -var-file=$VARFILE $ARGS
  fi
else
  workspace_account_destroy "$DIR/provision/log-delivery" $ACCOUNT_NAME -var-file=$VARFILE $ARGS
fi
