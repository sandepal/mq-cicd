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
kdb_name=$9
githubcreds_file=${10}
githubcreds_name=${11}
qmgr_name_1=${12}
qmgr_name_2=${13}

set -x

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
# name: kdb_name
# value: "ace-mqkey"
# name: githubcreds_file
# value: "GitHubCredentials.txt"
# name: githubcreds_name
# value: "github-creds"
# name: qmgr_name_1
# value: {{QMGR_NAME_1}}
# name: qmgr_name_2
# value: {{QMGR_NAME_2}}

cd /tmp

#policy
python -m zipfile -c $policy_name.zip $source_git_dir/$policy_dir
MQPOLICYZIP_BASE64=$(base64 -w0 $policy_name.zip)

#convert _ to - , _ is invalid for metadata.name
policy_name=${policy_name//_/-}

cat $source_git_dir/$config_dir/ace-policyzip-Configuration.yaml_template |
          sed "s#{{NAMESPACE}}#$namespace#g;" |
          sed "s#{{MQPOLICYZIP_NAME}}#$policy_name#g;" |
          sed "s#{{MQPOLICYZIP_BASE64}}#$MQPOLICYZIP_BASE64#g;" > ace-policyzip-Configuration-$namespace.yaml

cat ace-policyzip-Configuration-$namespace.yaml
oc apply -f ace-policyzip-Configuration-$namespace.yaml


#csv
csvzip_name="${csv_filename%.csv}.zip"
python -m zipfile -c $csvzip_name $source_git_dir/$config_dir/$csv_filename
CUSTTRANSZIP_BASE64=$(base64 -w0 $csvzip_name)

cat $source_git_dir/$config_dir/ace-customertransactionzip-Secret.yaml_template |
        sed "s#{{NAMESPACE}}#$namespace#g;" |
        sed "s#{{CUSTTRANSZIP_NAME}}#$csvzip_name#g;" |
        sed "s#{{CUSTTRANSZIP_BASE64}}#$CUSTTRANSZIP_BASE64#g;" > ace-customertransactionzip-Secret-$namespace.yaml

cat ace-customertransactionzip-Secret-$namespace.yaml
oc apply -f ace-customertransactionzip-Secret-$namespace.yaml

cat $source_git_dir/$config_dir/ace-customertransactionzip-Configuration.yaml_tamplate |
        sed "s#{{NAMESPACE}}#$namespace#g;" |
        sed "s#{{CUSTTRANSZIP_NAME}}#$csvzip_name#g;" > ace-customertransactionzip-Configuration-$namespace.yaml
	  
cat ace-customertransactionzip-Configuration-$namespace.yaml
oc apply -f ace-customertransactionzip-Configuration-$namespace.yaml

#ccdt

cat $source_git_dir/$config_dir/ace-ccdt.json_tamplate |
        sed "s#{{NAMESPACE}}#$namespace#g;" |
		sed "s#{{QMGR_NAME_1}}#$qmgr_name_1#g;" |
		sed "s#{{QMGR_NAME_2}}#$qmgr_name_2#g;" > ace-ccdt-$namespace.json


ccdt_name="ace-ccdt"
CCDT_BASE64=$(base64 -w0 $source_git_dir/$config_dir/ace-ccdt-$namespace.json)

cat $source_git_dir/$config_dir/ace-ccdt-Configuration.yaml_template |
          sed "s#{{NAMESPACE}}#$namespace#g;" |
          sed "s#{{CCDTCONFIG_NAME}}#$ccdt_name#g;" |
          sed "s#{{CCDT_BASE64}}#$CCDT_BASE64#g;" > ace-ccdt-Configuration-$namespace.yaml

cat ace-ccdt-Configuration-$namespace.yaml
oc apply -f ace-ccdt-Configuration-$namespace.yaml

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

oc apply -f ace-keystore-Secret-kdb-$namespace.yaml
oc apply -f ace-keystore-Secret-sth-$namespace.yaml
oc apply -f ace-keystore-Configuration-kdb-$namespace.yaml
oc apply -f ace-keystore-Configuration-sth-$namespace.yaml

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
oc apply -f ace-serverconf-Configuration-$namespace.yaml


#github_creds
GITHUBCREDS_BASE64=$(base64 -w0 $source_git_dir/$config_dir/$githubcreds_file)

cat $source_git_dir/$config_dir/ace-credentialsForGitHub-Secret.yaml_template |
        sed "s#{{NAMESPACE}}#$namespace#g;" |
        sed "s#{{GITHUBSECRET_NAME}}#$githubcreds_name#g;" |
        sed "s#{{GITHUBCREDS_BASE64}}#$GITHUBCREDS_BASE64#g;" > ace-credentialsForGitHub-Secret-$namespace.yaml

cat ace-credentialsForGitHub-Secret-$namespace.yaml
oc apply -f ace-credentialsForGitHub-Secret-$namespace.yaml

cat $source_git_dir/$config_dir/ace-credentialsForGitHub-Configuration.yaml_template |
        sed "s#{{NAMESPACE}}#$namespace#g;" |
        sed "s#{{GITHUBSECRET_NAME}}#$githubcreds_name#g;" > ace-credentialsForGitHub-Configuration-$namespace.yaml
	  
cat ace-credentialsForGitHub-Configuration-$namespace.yaml
oc apply -f ace-credentialsForGitHub-Configuration-$namespace.yaml

ls -la .

