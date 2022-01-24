#!/bin/bash

set -e

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

$DIR/provision.sh -vf secrets.tfvars $@

$DIR/workspace.sh $@
