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

oc get pods -n humanitec-operator-system

echo done

