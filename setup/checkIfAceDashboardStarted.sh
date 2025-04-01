#!/bin/bash
#******************************************************************************
# Licensed Materials - Property of IBM
# (c) Copyright IBM Corporation 2023. All Rights Reserved.
#
# Note to U.S. Government Users Restricted Rights:
# Use, duplication or disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
#******************************************************************************

set -e

namespace="$1"
name="$2"

CONDITION_TYPE=""
CONDITION_STATUS=""
wait_time=5  # Check every 5 seconds
time=0
timeout=300  # 5 minutes

while [[ "$CONDITION_TYPE" != "Ready" || "$CONDITION_STATUS" != "True" ]]; do
        CONDITION_TYPE=$(oc get dashboard $name -n $namespace -o=jsonpath='{.status.conditions[].type}' 2>/dev/null)
        CONDITION_STATUS=$(oc get dashboard $name -n $namespace -o=jsonpath='{.status.conditions[].status}' 2>/dev/null)
        
        ((time += wait_time))
        sleep $wait_time

        if [[ $time -ge $timeout ]]; then
            echo "ERROR: Timeout reached. dashboard $name did not become READY within 30 minutes."
            exit 1
        fi

        if [[ $time -ge 300 ]]; then
            echo "INFO: Waited over 15 minutes..."
        fi
    done

    echo "dashboard $name is READY."