#!/bin/bash

set -e

ACCOUNT_ID=
USERNAME=
PASSWORD=
VARFILE=

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
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -n "$ACCOUNT_ID" ]; then
export TF_VAR_databricks_account_id=$ACCOUNT_ID
fi
if [ -n "$USERNAME" ]; then
export TF_VAR_databricks_account_username=$USERNAME
fi
if [ -n "$PASSWORD" ]; then
export TF_VAR_databricks_account_password=$PASSWORD
fi

TFAPPLY=(terraform apply -auto-approve) # terraform apply innitial command
if [ -n "$VARFILE" ]; then
TFAPPLY+=( -var-file=$VARFILE)
fi

terraform init

# Apply terraform template to provision AWS and Databricks infra for a Workspace
"${TFAPPLY[@]}"

# Need to setup Databricks VPC Endpoint DNS resolution which can only be done after the VPC Endpoint has been accepted after configuration
"${TFAPPLY[@]}" -var="private_dns_enabled=true"
