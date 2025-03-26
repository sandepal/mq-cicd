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
file_storage=${2:-"ocs-storagecluster-cephfs"}
BLOCK_STORAGE=${3:-"ocs-storagecluster-ceph-rbd"}
PATCH_STORAGE=${4:-true}

oc new-project $namespace
oc project $namespace

#setup/deploy.sh $namespace

if [ "$PATCH_STORAGE" = true ] ; then
  kubectl patch storageclass $file_storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
fi


KEY_FILE=".tekton_git"
SECRET_NAME="git-ssh-key"

# Generate SSH key pair if not already present
if [[ ! -f "$KEY_FILE" ]]; then
  echo "Generating SSH key..."
  ssh-keygen -t rsa -b 4096 -C "tekton@ci" -f "$KEY_FILE" -N ""
  
  # Show public key and remind user to add it to GitHub
  echo "Copy this public key to GitHub (Settings > SSH Keys):"
  echo "------------------------------------------------------"
  cat "${KEY_FILE}.pub"
  echo "------------------------------------------------------"
  read -p "Press Enter after uploading it to GitHub..."  
else
  echo "SSH key already exists, skipping generation."
fi


ssh-keyscan github.com > known_hosts

# Create or update the secret in OpenShift
oc create secret generic $SECRET_NAME \
  --from-file=ssh-privatekey="$KEY_FILE" \
  --from-file=known_hosts=known_hosts \
  --type=kubernetes.io/ssh-auth \
  -n $namespace \
  --dry-run=client -o yaml | oc apply -f -

echo "Secret '$SECRET_NAME' is ready in namespace '$namespace'"




KEY_FILE=".ibm_entitlement_key"

# Check if file exists and is not empty
if [[ -s "$KEY_FILE" ]]; then
    IBM_ENTITLEMENT_KEY=$(cat "$KEY_FILE")
else
    # Prompt user for input
    read -sp "Enter IBM Entitlement Key: " IBM_ENTITLEMENT_KEY
    echo
    # Save to file for future use
    echo "$IBM_ENTITLEMENT_KEY" > "$KEY_FILE"
fi

# Create ibm-entitlement-key
oc create secret docker-registry ibm-entitlement-key \
  --docker-server=cp.icr.io \
  --docker-username=cp \
  --docker-password="$IBM_ENTITLEMENT_KEY" \
  -n $namespace


oc create serviceaccount pipeline-admin -n $namespace
oc create clusterrolebinding cicd-pipeline-admin-crb-$namespace --clusterrole=cluster-admin --serviceaccount=$namespace:pipeline-admin
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:$namespace:pipeline-admin

oc secrets link pipeline-admin ibm-entitlement-key --for=pull -n $namespace
oc secrets link pipeline-admin $SECRET_NAME --for=mount -n $namespace

oc apply -f pipeline/git-clone-task.yaml
sleep 10

#cat pipeline/cicd-environment-setup.yaml_template |
#       sed "s#{{DEFAULT_FILE_STORAGE}}#$file_storage#g;" |
#       sed "s#{{NAMESPACE}}#$namespace#g;" > cicd-environment-setup$namespace.yaml
#oc apply -f cicd-environment-setup$namespace.yaml
#rm cicd-environment-setup$namespace.yaml

cat pipeline/cicd-storage.yaml_template |
       sed "s#{{DEFAULT_FILE_STORAGE}}#$file_storage#g;" |
       sed "s#{{NAMESPACE}}#$namespace#g;" > cicd-storage$namespace.yaml

oc apply -f cicd-storage$namespace.yaml
rm cicd-storage$namespace.yaml

export SRCREPO=https://github.com/sandepal/mq-cicd.git
export TRGTREPO=https://github.com/sandepal/mq-argocd.git
export BRANCH=main
export TARGET_NAMESPACE=${1:-"cp4i"}
export QMGR_NAME_1=ucqm1
export QMGR_NAME_2=ucqm2

cat pipeline/cicd-push.yaml_template |
       sed "s#{{SRCREPO}}#$SRCREPO#g;" |
	   sed "s#{{TRGTREPO}}#$TRGTREPO#g;" |
       sed "s#{{NAMESPACE}}#$TARGET_NAMESPACE#g;" |
       sed "s#{{BRANCH}}#$BRANCH#g;" |
       sed "s#{{QMGR_NAME_1}}#$QMGR_NAME_1#g;" |
       sed "s#{{QMGR_NAME_2}}#$QMGR_NAME_2#g;" > cicd-push$namespace.yaml
oc apply -f cicd-push$namespace.yaml
#rm cicd-push$namespace.yaml

#sleep 30

#URL=$( oc get routes -n $namespace el-environment-setup-pipeline-trigger-route -o jsonpath={.spec.host})
#echo {\"namespace\": \"$namespace\"} >> JSON$namespace
#curl -d @JSON$namespace http://$URL
#rm JSON$namespace
