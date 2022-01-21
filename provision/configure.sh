#!/bin/bash

set -e

ACCOUNT_ID=
USERNAME=
PASSWORD=
VARFILE=
WORKSPACE_NAME=
IGW=
NOCMK=

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
    -igw)
      IGW=true
      shift # past argument
      ;;
    -nocmk|--no_customer_managed_keys)
      NOCMK="$2"
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

TFAPPLY=(terraform apply -auto-approve) # terraform apply initial command
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
if [ -n "$IGW" ] && [ "$IGW" = "true" ]; then
TFAPPLY+=( -var="allow_outgoing_internet=true")
fi
if [ -n "$NOCMK" ]; then
if [ "$NOCMK" = "all" ]; then
TFAPPLY+=( -var="cmk_managed=false")
TFAPPLY+=( -var="cmk_storage=false")
else
TFAPPLY+=( -var="cmk_$NOCMK=false")
fi
fi

terraform init

# Apply terraform template to provision AWS and Databricks infra for a Workspace
"${TFAPPLY[@]}"

# Need to setup Databricks VPC Endpoint DNS resolution which can only be done after the VPC Endpoint has been accepted after configuration
"${TFAPPLY[@]}" -var="private_dns_enabled=true"
