#!/bin/bash

set -e

pushd workspace
terraform init
set +e
terraform destroy -auto-approve
set -e
popd

pushd provision
terraform init
terraform destroy -auto-approve -var-file secrets.tfvars
popd
