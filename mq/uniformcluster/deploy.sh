#!/bin/bash
#******************************************************************************
# Licensed Materials - Property of IBM
# (c) Copyright IBM Corporation 2023. All Rights Reserved.
#
# Note to U.S. Government Users Restricted Rights:
# Use, duplication or disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
#******************************************************************************

export TARGET_NAMESPACE=${1:-"cp4i"}
export BRANCH=${2:-"main"}
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Deploying $BRANCH branch"

if [ "$BRANCH" == "main" ]; then
    $SCRIPT_DIR/deploy/deploy2QM.sh $TARGET_NAMESPACE
    $SCRIPT_DIR/deploy/checkIfStarted.sh $TARGET_NAMESPACE ucqm1
    $SCRIPT_DIR/deploy/checkIfStarted.sh $TARGET_NAMESPACE ucqm2
fi

