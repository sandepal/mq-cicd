#!/bin/bash
#******************************************************************************
# Licensed Materials - Property of IBM
# (c) Copyright IBM Corporation 2023. All Rights Reserved.
#
# Note to U.S. Government Users Restricted Rights:
# Use, duplication or disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
#******************************************************************************

namespace=$1
source_git_dir=$2
config_dir=$3
ir_name=$4
git_bar_url=$5
config_list=$6


set -x

# name: namespace
# value: {{CI_NAMESPACE}}
# name: source_git_dir
# value: "/workspace/git-ws/srcrepos"
# name: config_dir
# value: "ace/resources/configuration"
# name: ir_name
# value: "ir-01"
# name: git_bar_url
# value: "https://git_bar_url"
# name: config_list
# value: "ace-ccdt,ace-mqkey.kdb,ace-mqkey.sth,ace-serverconf,generate-test-data-mqpolicy,github-creds"


cd /tmp

config_yaml=""
IFS=',' read -ra configs <<< "$config_list"
for config in "${configs[@]}"; do
  config_yaml="${config_yaml}    - ${config}\n"
done

cat $source_git_dir/$config_dir/ace-IntegrationRuntime.yaml_template |
          sed "s#{{NAMESPACE}}#$namespace#g;" |
          sed "s#{{BAR_URL}}#$git_bar_url#g;" |
          sed "s#{{IR_NAME}}#$ir_name#g;" |
		  sed "s#{{CONFIG_NAME}}#$config_yaml#g;" > ace-IntegrationRuntime-$namespace.yaml

cat ace-IntegrationRuntime-$namespace.yaml
oc apply -f ace-IntegrationRuntime-$namespace.yaml

ls -la .
