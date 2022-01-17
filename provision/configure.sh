#!/bin/bash

set -e

ACCOUNT_ID=
USERNAME=
PASSWORD=
VARFILE=
WORKSPACE_NAME=

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -a|--account_id)
      ACCOUNT_ID="$2"
      shift # past argument
      shift # past value
      ;;
    -u|--username)
      USERNAME="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--password)
      PASSWORD="$2"
      shift # past argument
      shift # past value
      ;;
    -vf|--var-file)
      VARFILE="$2"
      shift # past argument
      shift # past value
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

TFAPPLY=(terraform apply -auto-approve) # terraform apply innitial command
if [ -n "$VARFILE" ]; then
TFAPPLY+=( -var-file=$VARFILE)
fi
if [ -n "$ACCOUNT_ID" ]; then
TFAPPLY+=( -var="databricks_account_id=$ACCOUNT_ID")
fi
if [ -n "$USERNAME" ]; then
TFAPPLY+=( -var="databricks_account_username=$USERNAME")
fi
if [ -n "$PASSWORD" ]; then
TFAPPLY+=( -var="databricks_account_username=$PASSWORD")
fi
if [ -n "$WORKSPACE_NAME" ]; then
TFAPPLY+=( -var="databricks_workspace_name=$WORKSPACE_NAME")
fi

terraform init

# Apply terraform template to provision AWS and Databricks infra for a Workspace
"${TFAPPLY[@]}"

# Need to setup Databricks VPC Endpoint DNS resolution which can only be done after the VPC Endpoint has been accepted after configuration
"${TFAPPLY[@]}" -var="private_dns_enabled=true"
