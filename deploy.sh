#!/bin/bash
#******************************************************************************
# Licensed Materials - Property of IBM
# (c) Copyright IBM Corporation 2023. All Rights Reserved.
#
# Note to U.S. Government Users Restricted Rights:
# Use, duplication or disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
#******************************************************************************

# Set Git repository and MQ details
ci_namespace="cp4i"
cd_namespace="ucqm-demo"
qmgr_name_1="ucqm1"
qmgr_name_2="ucqm2"
srcrepos="https://github.com/sandepal/mq-cicd.git"
trgtrepos="https://github.com/sandepal/mq-argocd.git"
branch="main"
file_storage="ocs-storagecluster-cephfs"
block_storage="ocs-storagecluster-ceph-rbd"

# Create the target namespace if it doesn't exist
oc get ns $cd-namespace >/dev/null 2>&1 || oc new-project $cd_namespace
oc get ns $ci_namespace >/dev/null 2>&1 || oc new-project $ci_namespace
oc project $ci_namespace

key_file=".tekton_git"
secret_name="git-ssh-key"

# Generate SSH key pair if not already present
if [[ ! -f "$key_file" ]]; then
  echo "Generating SSH key..."
  ssh-keygen -t rsa -b 4096 -C "tekton@ci" -f "$key_file" -N ""
  
  # Show public key and remind user to add it to GitHub
  echo "Copy this public key to GitHub (Settings > SSH Keys):"
  echo "------------------------------------------------------"
  cat "${key_file}.pub"
  echo "------------------------------------------------------"
  read -p "Press Enter after uploading it to GitHub..."  
else
  echo "SSH key already exists, skipping generation."
fi

ssh-keyscan github.com > known_hosts

# Create or update the secret in OpenShift
oc create secret generic $secret_name \
  --from-file=ssh-privatekey="$key_file" \
  --from-file=known_hosts=known_hosts \
  --type=kubernetes.io/ssh-auth \
  -n $ci_namespace \
  --dry-run=client -o yaml | oc apply -f -

echo "Secret '$secret_name' is ready in namespace '$ci_namespace'"

entitlement_key=".ibm_entitlement_key"

# Check if file exists and is not empty
if [[ -s "$entitlement_key" ]]; then
    IBM_ENTITLEMENT_KEY=$(cat "$entitlement_key")
else
    # Prompt user for input
    read -sp "Enter IBM Entitlement Key: " IBM_ENTITLEMENT_KEY
    echo
    # Save to file for future use
    echo "$IBM_ENTITLEMENT_KEY" > "$entitlement_key"
fi

# Create ibm-entitlement-key
oc create secret docker-registry ibm-entitlement-key \
  --docker-server=cp.icr.io \
  --docker-username=cp \
  --docker-password="$IBM_ENTITLEMENT_KEY" \
  -n $ci_namespace

oc create serviceaccount pipeline-admin -n $ci_namespace
oc create clusterrolebinding cicd-pipeline-admin-crb-$ci_namespace --clusterrole=cluster-admin --serviceaccount=$ci_namespace:pipeline-admin
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:$ci_namespace:pipeline-admin

oc secrets link pipeline-admin ibm-entitlement-key --for=pull -n $ci_namespace
oc secrets link pipeline-admin $secret_name --for=mount -n $ci_namespace

cat pipeline/cicd-storage.yaml_template |
       sed "s#{{DEFAULT_FILE_STORAGE}}#$file_storage#g;" |
       sed "s#{{CI_NAMESPACE}}#$ci_namespace#g;" > cicd-storage$ci_namespace.yaml

oc apply -f cicd-storage$ci_namespace.yaml
rm cicd-storage$ci_namespace.yaml

cat pipeline/cicd-initialise.yaml_template |
       sed "s#{{SRCREPOS}}#$srcrepos#g;" |
       sed "s#{{TRGTREPOS}}#$trgtrepos#g;" |
       sed "s#{{CI_NAMESPACE}}#$ci_namespace#g;" |
	   sed "s#{{CD_NAMESPACE}}#$cd_namespace#g;" |
       sed "s#{{BRANCH}}#$branch#g;" |
       sed "s#{{QMGR_NAME_1}}#$qmgr_name_1#g;" |
       sed "s#{{QMGR_NAME_2}}#$qmgr_name_2#g;" > cicd-initialise$ci_namespace.yaml

# Step 1: Create pipeline + tasks
oc apply -f cicd-initialise$ci_namespace.yaml \
  --prune -l part=ci-definition \
  --prune-allowlist=tekton.dev/v1beta1/Task \
  --prune-allowlist=tekton.dev/v1beta1/Pipeline

# Step 2: Then create the PipelineRun
oc apply -f cicd-initialise$ci_namespace.yaml \
  --prune -l part=ci-run \
  --prune-allowlist=tekton.dev/v1beta1/PipelineRun

rm cicd-initialise$ci_namespace.yaml


