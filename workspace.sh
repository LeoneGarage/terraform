#!/bin/bash

set -e

pushd workspace
terraform init
terraform apply -auto-approve
popd
