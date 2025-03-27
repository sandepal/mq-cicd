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

# Load env variables
if [ -f pipeline.env ]; then
  echo "Loading environment variables from pipeline.env"  
  source pipeline.env
else
  echo "pipeline.env not found!"
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