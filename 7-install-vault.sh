#!/bin/bash
# install hashicorp key vault
# https://developer.hashicorp.com/vault/docs/platform/k8s/helm/openshift
set -euo pipefail

echo you need to have vault cli installed locally
vault -version

echo installing hashicorp vault with helm in ${VAULT_NAMESPACE} namespace

helm install vault hashicorp/vault \
    --set "global.openshift=true" \
    --namespace=${VAULT_NAMESPACE} \
    --create-namespace

# expose vault endpoint
echo creating public route
oc -n ${VAULT_NAMESPACE} create route edge --insecure-policy=None --port=8200 --service=vault vault

# get the url
export VAULT_ADDR=https://$(oc -n ${VAULT_NAMESPACE} get route | grep -m1 vault | awk '{print $2}')
echo vault route: ${VAULT_ADDR} 

# init the vault
echo initializing the vault ... follow instructions manually
oc -n ${VAULT_NAMESPACE} exec -ti vault-0 -- vault operator init

echo ATTENTION: copy the Unseal Keys to use next times
echo ATTENTION: copy the Initial Root Token

# unseal the vault execute 3 times
echo unseal the vault with the following command with 3 keys you copied
echo oc -n ${VAULT_NAMESPACE} exec -ti vault-0 -- vault operator unseal <key>

echo login to the vault (provide the root token)
echo vault login

echo done

