#!/bin/bash
#******************************************************************************
# Licensed Materials - Property of IBM
# (c) Copyright IBM Corporation 2023. All Rights Reserved.
#
# Note to U.S. Government Users Restricted Rights:
# Use, duplication or disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
#******************************************************************************

namespace=${1:-"cp4i"}

#oc new-project $namespace
oc project $namespace

#hostname=$(oc get route el-infinite-cleanup-pipeline-trigger-route -o jsonpath={.spec.host})
#
#response=$(curl -d "{}" $hostname)
#echo $response
#
#sleep 60s

oc delete pipelineruns --all -n $namespace
oc delete pipeline --all -n $namespace
oc delete task --all -n $namespace
oc delete taskrun --all -n $namespace
#oc delete clustertask git-clone
oc delete eventlistener --all -n $namespace
oc delete triggertemplate --all -n $namespace
oc delete triggerbinding --all -n $namespace
oc delete route -l eventlistener -n $namespace
oc delete pod cicd-log-pod -n $namespace


oc delete pvc -n $namespace git-source-workspace


