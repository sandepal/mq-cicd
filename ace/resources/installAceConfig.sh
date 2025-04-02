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
policy_dir=$4
policy_name=$5
mqcert_dir=$6
mqcert_names=$7
csv_filename=$8
ccdt_filename=$9
kdb_name=$10

# name: namespace
# value: {{CI_NAMESPACE}}
# name: setupConfig_script
# value: "ace/resources/installAceConfig.sh"
# name: source_git_dir
# value: "/workspace/git-ws/srcrepos"
# name: config_dir
# value: "ace/resources/configuration"
# name: policy_dir
# value: "ace/resources/source/gitops_demo_mqpolicy"
# name: policy_name
# value: "gitops_demo_mqpolicy"
# name: mqcert_dir
# value: "mq/resources"
# name: mqcert_names
# value: "tls-ucqm1-cert-secret.crt tls-ucqm2-cert-secret.crt"         
# name: csv_filename
# value: "customer_transactions.csv"        
# name: ccdt_filename
# value: "ace-ccdt.json"

  
cd /tmp

#policy
python -m zipfile -c $policy_name.zip $source_git_dir/$policy_dir
MQPOLICYZIP_BASE64=$(base64 -w0 $policy_name.zip)

cat $source_git_dir/$config_dir/ace-policyzip-Configuration.yaml_template |
          sed "s#{{NAMESPACE}}#$namespace#g;" |
          sed "s#{{MQPOLICYZIP_NAME}}#$policy_name#g;" |
          sed "s#{{MQPOLICYZIP_BASE64}}#$MQPOLICYZIP_BASE64#g;" > ace-policyzip-Configuration-$namespace.yaml

cat ace-policyzip-Configuration-$namespace.yaml

#csv
if [ -n "$csv_filename" ]; then
  csvzip_name="${csv_filename%.csv}.zip"
  python -m zipfile -c $csvzip_name $csv_filename
  CUSTTRANSZIP_BASE64=$(base64 -w0 $csvzip_name)
  
  cat $source_git_dir/$config_dir/ace-customertransactionzip-Secret.yaml_template |
          sed "s#{{NAMESPACE}}#$namespace#g;" |
          sed "s#{{CUSTTRANSZIP_NAME}}#$csvzip_name#g;" |
          sed "s#{{CUSTTRANSZIP_BASE64}}#$CUSTTRANSZIP_BASE64#g;" > ace-customertransactionzip-Secret-$namespace.yaml
  
  cat ace-customertransactionzip-Secret-$namespace.yaml
  
  cat $source_git_dir/$config_dir/ace-customertransactionzip-Configuration.yaml_tamplate |
          sed "s#{{NAMESPACE}}#$namespace#g;" |
          sed "s#{{CUSTTRANSZIP_NAME}}#$csvzip_name#g;" > ace-customertransactionzip-Configuration-$namespace.yaml
		  
  cat ace-customertransactionzip-Configuration-$namespace.yaml

else
  echo "csv_name is empty. Skipping zip."
fi


#ccdt
ccdt_name="${ccdt_filename%.json}"
CCDT_BASE64=$(base64 -w0 $source_git_dir/$config_dir/$ccdt_filename)

cat $source_git_dir/$config_dir/ace-ccdt-Configuration.yaml_template |
          sed "s#{{NAMESPACE}}#$namespace#g;" |
          sed "s#{{CCDTCONFIG_NAME}}#$ccdt_name#g;" |
          sed "s#{{CCDT_BASE64}}#$CCDT_BASE64#g;" > ace-ccdt-Configuration-$namespace.yaml

cat ace-ccdt-Configuration-$namespace.yaml

#truststore
ls -la $source_git_dir/$config_dir

KDB_BASE64=$(base64 -w0 $source_git_dir/$config_dir/$kdb_name.kdb)
STH_BASE64=$(base64 -w0 $source_git_dir/$config_dir/$kdb_name.sth)

cat $source_git_dir/$config_dir/ace-keystore-Secret.yaml_template |
          sed "s#{{NAMESPACE}}#$namespace#g;" |
          sed "s#{{KDBKEYSTORESECRET_NAME}}#$kdb_name-kdb#g;" |
          sed "s#{{KDBKEYSTORE_BASE64}}#$KDB_BASE64#g;" > ace-keystore-Secret-kdb-$namespace.yaml

cat $source_git_dir/$config_dir/ace-keystore-Secret.yaml_template |
          sed "s#{{NAMESPACE}}#$namespace#g;" |
          sed "s#{{KDBKEYSTORESECRET_NAME}}#$kdb_name-sth#g;" |
          sed "s#{{KDBKEYSTORE_BASE64}}#$STH_BASE64#g;" > ace-keystore-Secret-sth-$namespace.yaml

cat $source_git_dir/$config_dir/ace-keystore-Configuration.yaml_template |
          sed "s#{{NAMESPACE}}#$namespace#g;" |
          sed "s#{{KDBKEYSTORE_NAME}}#$kdb_name.kdb#g;" |
          sed "s#{{KDBKEYSTORESECRET_NAME}}#$kdb_name-kdb#g;" > ace-keystore-Configuration-kdb-$namespace.yaml

cat $source_git_dir/$config_dir/ace-keystore-Configuration.yaml_template |
          sed "s#{{NAMESPACE}}#$namespace#g;" |
          sed "s#{{KDBKEYSTORE_NAME}}#$kdb_name.sth#g;" |
          sed "s#{{KDBKEYSTORESECRET_NAME}}#$kdb_name-sth#g;" > ace-keystore-Configuration-sth-$namespace.yaml

cat ace-keystore-Secret-kdb-$namespace.yaml
cat ace-keystore-Secret-sth-$namespace.yaml
cat ace-keystore-Configuration-kdb-$namespace.yaml
cat ace-keystore-Configuration-sth-$namespace.yaml

#serverconf

cat $source_git_dir/$config_dir/ace-serverconf.yaml_template |
          sed "s#{{KDBKEYSTORE_NAME}}#$kdb_name#g;" > ace-serverconf-$namespace.yaml

cat ace-serverconf-$namespace.yaml

SERVERCONF_BASE64=$(base64 -w0 ace-serverconf-$namespace.yaml)
SERVERCONF_NAME="ace-serverconf"

cat $source_git_dir/$config_dir/ace-serverconf-Configuration.yaml_template |
          sed "s#{{NAMESPACE}}#$namespace#g;" |
          sed "s#{{SERVERCONF_NAME}}#$SERVERCONF_NAME#g;" |
          sed "s#{{SERVERCONF_BASE64}}#$SERVERCONF_BASE64#g;" > ace-serverconf-Configuration-$namespace.yaml

cat ace-serverconf-Configuration-$namespace.yaml

ls -la .





