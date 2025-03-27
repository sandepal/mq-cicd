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

env_file_path="${1:-../pipeline/pipeline.env}"
mq_yaml_dir="${2:-resources}"

# Load env variables
if [ -f "$env_file_path" ]; then
  echo "Loading environment variables from pipeline.env"  
  source "$env_file_path"
else
  echo "$env_file_path not found!"
  exit 1
fi

cd $mq_yaml_dir

cat configmap-QM.yaml_template |
       sed "s#{{NAMESPACE}}#$ci_namespace#g;" |
       sed "s#{{QMGR_NAME_1}}#$qmgr_name_1#g;" |
       sed "s#{{QMGR_NAME_2}}#$qmgr_name_2#g;" > configmap-QM$ci_namespace.yaml

cat queuemanager-QM1.yaml_template |
       sed "s#{{NAMESPACE}}#$ci_namespace#g;" |
       sed "s#{{QMGR_NAME_1}}#$qmgr_name_1#g;" |
       sed "s#{{QMGR_NAME_2}}#$qmgr_name_2#g;" > queuemanager-QM1$ci_namespace.yaml

cat queuemanager-QM2.yaml_template |
       sed "s#{{NAMESPACE}}#$ci_namespace#g;" |
       sed "s#{{QMGR_NAME_1}}#$qmgr_name_1#g;" |
       sed "s#{{QMGR_NAME_2}}#$qmgr_name_2#g;" > queuemanager-QM2$ci_namespace.yaml
	   
oc apply -f configmap-QM$ci_namespace.yaml
oc apply -f queuemanager-QM1$ci_namespace.yaml
oc apply -f queuemanager-QM2$ci_namespace.yaml