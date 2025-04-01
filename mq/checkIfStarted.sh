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
queuemanager="$2"


# wait 10 minutes for queue manager to be up and running
# (shouldn't take more than 2 minutes, but just in case)
for i in {1..60}
do
  phase=`oc get qmgr -n $namespace $queuemanager -o jsonpath="{.status.phase}"`
  if [ "$phase" == "Running" ] ; then break; fi
  echo "Waiting for $queuemanager...$i"
  oc get qmgr -n $namespace $queuemanager
  sleep 10
done

if [ $phase == Running ]
   then echo Queue Manager $queuemanager is ready;
   exit;
fi

echo "*** Queue Manager $queuemanager is not ready ***"
exit 1
