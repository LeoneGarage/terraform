#!/bin/bash

set -e

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

WORKSPACE_NAME=

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
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

$DIR/configure_tf_workspace.sh $WORKSPACE_NAME

CONFIGURE=($DIR/provision/configure.sh -vf secrets.tfvars) # initial command
CONFIGURE+=( $* )
"${CONFIGURE[@]}"
