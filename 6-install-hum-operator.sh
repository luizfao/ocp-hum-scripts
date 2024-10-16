#!/bin/bash
# install humanitec-operator
# https://developer.humanitec.com/integration-and-extensions/humanitec-operator/installation/
set -euo pipefail

echo installing humanitec-operator with helm

helm install humanitec-operator \
  oci://ghcr.io/humanitec/charts/humanitec-operator \
  --namespace humanitec-operator-system \
  --create-namespace

# Operator secret keys - Config auth for drivers https://developer.humanitec.com/integration-and-extensions/humanitec-operator/installation/#configure-authentication-for-drivers
# Generate a new private key
echo create operator private and public keys, and secret to enable authentication for drivers
openssl genpkey -algorithm RSA -out humanitec_operator_private_key.pem -pkeyopt rsa_keygen_bits:4096

# Extract the public key from the private key generated in the previous command
openssl rsa -in humanitec_operator_private_key.pem -outform PEM -pubout -out humanitec_operator_public_key.pem

# create the secret
oc -n humanitec-operator-system create secret generic humanitec-operator-private-key \
     --from-file=privateKey=humanitec_operator_private_key.pem \
     --from-literal=humanitecOrganisationID=$HUMANITEC_ORG

# register in humanitec
humctl api post /orgs/${HUMANITEC_ORG}/keys \
  -d "$(cat humanitec_operator_public_key.pem | jq -sR)"

echo register operator public key exit code=$?

# sometimes operator pod goes out of memory with default memory limit, increase it to avoid this error
echo increase operator memory limit
oc -n humanitec-operator-system set resources deployment humanitec-operator-controller-manager --limits memory=256Mi

oc -n humanitec-operator-system get pods

echo done

