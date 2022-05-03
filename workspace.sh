#!/bin/bash

set -e

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. $DIR/utils.sh

WORKSPACE_NAME=
PLAN=
IMPORT=
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
      IMPORT=true
      shift # past argument
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
if [ -n "$PLAN" ] && [ "$PLAN" = "true" ]; then
  TFAPPLY=(terraform -chdir=$DIR/workspace plan -var="workspace=$ACCOUNT_NAME-$WORKSPACE_NAME")
else
  if [ -n "$IMPORT" ] && [ "$IMPORT" = "true" ]; then
    TFAPPLY=(terraform -chdir=$DIR/workspace import -var="workspace=$ACCOUNT_NAME-$WORKSPACE_NAME")
  else
    TFAPPLY=(terraform -chdir=$DIR/workspace apply -auto-approve -var="workspace=$ACCOUNT_NAME-$WORKSPACE_NAME")
  fi
fi
if [ -n "$REGION" ]; then
  TFAPPLY+=( -var="region=$REGION")
fi
if [ -n "$AWS_PROFILE" ]; then
  TFAPPLY+=( -var="aws_profile=$AWS_PROFILE")
fi


# Apply terraform template to provision Databricks Workspace
# If $FRONT_END_PL_SUBNET_IDS is provided will also create Front End VPC Endpoint in those subnets
"${TFAPPLY[@]}"
