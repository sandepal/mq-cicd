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

env_file_path="${1:-pipeline.env}"

# Load env variables
if [ -f "$env_file_path" ]; then
  echo "Loading environment variables from pipeline.env"  
  source "$env_file_path"
else
  echo "$env_file_path not found!"
  exit 1
fi

cat cicd-deploy-mq-pipeline.yaml_template |
       sed "s#{{SRCREPOS}}#$srcrepos#g;" |
       sed "s#{{TRGTREPOS}}#$trgtrepos#g;" |
       sed "s#{{CI_NAMESPACE}}#$ci_namespace#g;" |
	   sed "s#{{CD_NAMESPACE}}#$cd_namespace#g;" |
       sed "s#{{BRANCH}}#$branch#g;" |
       sed "s#{{QMGR_NAME_1}}#$qmgr_name_1#g;" |
       sed "s#{{QMGR_NAME_2}}#$qmgr_name_2#g;" |  
       sed "s#{{CI_NAMESPACE}}#$ci_namespace#g;" > cicd-deploy-mq-pipeline$ci_namespace.yaml

# Step 1: Create pipeline + tasks
oc apply -f cicd-deploy-mq-pipeline$ci_namespace.yaml \
  --prune -l part=ci-definition \
  --prune-allowlist=tekton.dev/v1beta1/Task \
  --prune-allowlist=tekton.dev/v1beta1/Pipeline

# Step 2: Then create the PipelineRun
oc apply -f cicd-deploy-mq-pipeline$ci_namespace.yaml \
  --prune -l part=ci-run \
  --prune-allowlist=tekton.dev/v1beta1/PipelineRun

rm cicd-deploy-mq-pipeline$ci_namespace.yaml
