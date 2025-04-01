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

ci_namespace="$1"
qmgr_name_1="$2"
qmgr_name_2="$3"
mq_yaml_dir="$4"

cd $mq_yaml_dir

cat configmap-QM.yaml_template |
       sed "s#{{NAMESPACE}}#$ci_namespace#g;" |
       sed "s#{{QMGRNAME_1}}#$qmgr_name_1#g;" |
       sed "s#{{QMGRNAME_2}}#$qmgr_name_2#g;" > configmap-QM$ci_namespace.yaml

cat queuemanager-QM1.yaml_template |
       sed "s#{{NAMESPACE}}#$ci_namespace#g;" |
       sed "s#{{QMGRNAME_1}}#$qmgr_name_1#g;" |
       sed "s#{{QMGRNAME_2}}#$qmgr_name_2#g;" > queuemanager-QM1$ci_namespace.yaml

cat queuemanager-QM2.yaml_template |
       sed "s#{{NAMESPACE}}#$ci_namespace#g;" |
       sed "s#{{QMGRNAME_1}}#$qmgr_name_1#g;" |
       sed "s#{{QMGRNAME_2}}#$qmgr_name_2#g;" > queuemanager-QM2$ci_namespace.yaml
	   
oc apply -f configmap-QM$ci_namespace.yaml
oc apply -f queuemanager-QM1$ci_namespace.yaml
oc apply -f queuemanager-QM2$ci_namespace.yaml