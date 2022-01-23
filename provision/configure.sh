#!/bin/bash

set -e

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ACCOUNT_ID=
USERNAME=
PASSWORD=
VARFILE=
WORKSPACE_NAME=
REGION=
# Internet Gateway on or off
IGW=
# No Customer Managed Keys
NOCMK=
# Only run terraform plan not apply
PLAN=
# Only import the resources
IMPORT_ADDR=
IMPORT_ID=
# Private or Public access for PrivateLink Front End
FRONT_END_ACCESS=
FRONT_END_PL_SUBNET_IDS=
FROND_END_PL_SOURCE_SUBNET_IDS=
# PrivateLink on or off
NOPL=

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
    -r|--region)
      REGION="$2"
      shift # past argument
      shift # past value
      ;;
    -w|--workspace)
      WORKSPACE_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    -igw|--internet-gateway)
      IGW=true
      shift # past argument
      ;;
    -nocmk|--no_customer_managed_keys)
      NOCMK="$2"
      shift # past argument
      shift # past value
      ;;
    -plan|--plan)
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
    -fea|--front_end_access)
      FRONT_END_ACCESS="$2"
      shift # past argument
      shift # past value
      ;;
    -feplsids|--front_end_pl_subnet_ids)
      FRONT_END_PL_SUBNET_IDS="$2"
      shift # past argument
      shift # past value
      ;;
    -feplsrcsids|--front_end_pl_source_subnet_ids)
      FROND_END_PL_SOURCE_SUBNET_IDS="$2"
      shift # past argument
      shift # past value
      ;;
    -nopl|--no-privatelink)
      NOPL=true
      # We also need NAT and IGW without PrivateLink
      IGW=true
      shift # past argument
      ;;
    *)    # unknown option
      echo "Unknown option $1"
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -n "$VARFILE" ]; then
  VARFILE="$(cd "$(dirname "$VARFILE")"; pwd)/$(basename "$VARFILE")"
fi

CURR_W=$(terraform -chdir=$DIR/.. workspace show)
if [ -z "$WORKSPACE_NAME" ]; then
  if [ "$CURR_W" != "default" ]; then
    WORKSPACE_NAME=$CURR_W
  fi
fi
if [ -z "$WORKSPACE_NAME" ]; then
  RANDSTR=$(openssl rand -base64 12 | cut -c1-6 | sed 's/[^a-zA-Z0-9]//g')
  WORKSPACE_NAME="terratest-$RANDSTR"
fi

if [ "$WORKSPACE_NAME" != "$CURR_W" ]; then
  set +e
  terraform -chdir=$DIR workspace new $WORKSPACE_NAME
  set -e
  terraform -chdir=$DIR workspace select $WORKSPACE_NAME
fi

if [ -n "$PLAN" ] && [ "$PLAN" = "true" ]; then
  TFAPPLY=(terraform -chdir=$DIR plan)
else
  if [ -n "$IMPORT_ADDR" ] ; then
    TFAPPLY=(terraform -chdir=$DIR import)
  else
    TFAPPLY=(terraform -chdir=$DIR apply -auto-approve) # terraform apply initial command
  fi
fi
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
if [ -n "$REGION" ]; then
  TFAPPLY+=( -var="region=$REGION")
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
if [ -n "$NOPL" ] && [ "$NOPL" = "true" ]; then
  TFAPPLY+=( -var="private_link=false")
fi

terraform -chdir=$DIR init
set +e
terraform -chdir=$DIR workspace new $WORKSPACE_NAME
set -e
terraform -chdir=$DIR workspace select $WORKSPACE_NAME

if [ -n "$FRONT_END_PL_SUBNET_IDS" ]; then
  TFAPPLY+=( -var="front_end_pl_subnet_ids=$FRONT_END_PL_SUBNET_IDS")
fi

if [ -n "$FROND_END_PL_SOURCE_SUBNET_IDS" ]; then
  TFAPPLY+=( -var="front_end_pl_source_subnet_ids=$FROND_END_PL_SOURCE_SUBNET_IDS")
fi

if [ -n "$IMPORT_ADDR" ] ; then
  TFAPPLY+=( -target="$IMPORT_ADDR" $IMPORT_ADDR $IMPORT_ID)
fi
# Apply terraform template to provision AWS and Databricks infra for a Workspace
# If $FRONT_END_PL_SUBNET_IDS is provided will also create Front End VPC Endpoint in those subnets
"${TFAPPLY[@]}"

if [ -z "$IMPORT_ADDR" ] ; then
# Now if required we will adjust private access after the Workspace is created so we don't have to access it's URL since this may render it inaccessible
  if [ -n "$FRONT_END_ACCESS" ]; then
    TFAPPLY+=( -var="front_end_access=$FRONT_END_ACCESS")
  fi

  # Need to setup Databricks VPC Endpoint DNS resolution which can only be done after the VPC Endpoint has been accepted after configuration
  "${TFAPPLY[@]}" -var="private_dns_enabled=true"
fi