#!/bin/bash

set -e

./provision.sh -vf secrets.tfvars $*

./workspace.sh
