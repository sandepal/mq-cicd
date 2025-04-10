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

cat cicd-package-mq-pipelinerun.yaml_template |
       sed "s#{{SRCREPOS}}#$git_source_url#g;" |
       sed "s#{{TRGTREPOS}}#$git_target_url#g;" |
       sed "s#{{CI_NAMESPACE}}#$ci_namespace#g;" |
	   sed "s#{{CD_NAMESPACE}}#$cd_namespace#g;" |
       sed "s#{{BRANCH}}#$branch#g;" |
       sed "s#{{QMGR_NAME_1}}#$qmgr_name_1#g;" |
       sed "s#{{QMGR_NAME_2}}#$qmgr_name_2#g;" > cicd-package-mq-pipelinerun$ci_namespace.yaml
	   
cat cicd-package-mq.yaml_template |
       sed "s#{{SRCREPOS}}#$git_source_url#g;" |
       sed "s#{{TRGTREPOS}}#$git_target_url#g;" |
       sed "s#{{CI_NAMESPACE}}#$ci_namespace#g;" |
	   sed "s#{{CD_NAMESPACE}}#$cd_namespace#g;" |
       sed "s#{{BRANCH}}#$branch#g;" |
       sed "s#{{QMGR_NAME_1}}#$qmgr_name_1#g;" |
       sed "s#{{QMGR_NAME_2}}#$qmgr_name_2#g;" > cicd-package-mq$ci_namespace.yaml

oc apply -f cicd-package-mq$ci_namespace.yaml
oc apply -f cicd-package-mq-pipelinerun$ci_namespace.yaml

rm cicd-package-mq$ci_namespace.yaml
rm cicd-package-mq-pipelinerun$ci_namespace.yaml