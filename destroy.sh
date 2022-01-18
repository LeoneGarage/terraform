#!/bin/bash

# set -e

pushd workspace
terraform init
terraform destroy -auto-approve
popd

pushd provision
terraform init
terraform destroy -auto-approve -var-file secrets.tfvars
popd
