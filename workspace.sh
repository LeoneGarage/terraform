#!/bin/bash

set -e

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. $DIR/utils.sh

WORKSPACE_NAME=
PLAN=
# Only import the resources
IMPORT_ADDR=
IMPORT_ID=
REGION=
AWS_PROFILE=

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -plan)
      PLAN=true
      shift # past argument
      ;;
    -import)
      IMPORT_ADDR="$2"
      shift # past argument
      IMPORT_ID="$2"
      shift # past value
      shift # past value
      ;;
    -w|--workspace)
      WORKSPACE_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    -r|--region)
      REGION="$2"
      shift # past argument
      shift # past value
      ;;
    -ap|--aws-profile)
      AWS_PROFILE="$2"
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

terraform -chdir=$DIR/workspace init
workspace_create_if_not_exists $DIR/workspace $ACCOUNT_NAME $WORKSPACE_NAME
workspace_select "$DIR/workspace" $ACCOUNT_NAME $WORKSPACE_NAME
TFAPPLY=()
TFAPPLY_ARGS=()
if [ -n "$PLAN" ] && [ "$PLAN" = "true" ]; then
  TFAPPLY=(terraform -chdir=$DIR/workspace plan)
else
  if [ -n "$IMPORT_ADDR" ]; then
    TFAPPLY=(terraform -chdir=$DIR/workspace import)
  else
    TFAPPLY=(terraform -chdir=$DIR/workspace apply -auto-approve)
  fi
fi
TFAPPLY_ARGS+=( -var="workspace=$ACCOUNT_NAME-$WORKSPACE_NAME")
if [ -n "$REGION" ]; then
  TFAPPLY_ARGS+=( -var="region=$REGION")
fi
if [ -n "$AWS_PROFILE" ]; then
  TFAPPLY_ARGS+=( -var="aws_profile=$AWS_PROFILE")
fi

if [ -n "$IMPORT_ADDR" ]; then
  TFAPPLY_ARGS+=( -target="$IMPORT_ADDR" $IMPORT_ADDR $IMPORT_ID)
fi

# Apply terraform template to provision Databricks Workspace
# If $FRONT_END_PL_SUBNET_IDS is provided will also create Front End VPC Endpoint in those subnets
"${TFAPPLY[@]}" "${TFAPPLY_ARGS[@]}"
