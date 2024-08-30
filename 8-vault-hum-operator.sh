# configure hashicorp vault secrets manager for humanitec operator
# https://developer.humanitec.com/integration-and-extensions/humanitec-operator/how-tos/connect-to-hashicorp-vault/
set -euo pipefail

echo obtaining vault address
export VAULT_ADDR=https://$(oc -n vault get route | grep -m1 vault | awk '{print $2}')

# need to be logged in to the vault server
echo login to the hashicorp key vault -- please provide the token
echo VAULT_ADDR=${VAULT_ADDR}
vault login

# start vault config
vault secrets enable -version=2 -path=$SECRETS_PATH kv

# create humanitec orq read-write access policy 
echo using operator level read-write
export OPERATOR_ACCESS_LEVEL=read-write
cat << EOF > policy-$OPERATOR_ACCESS_LEVEL.hcl
path "$SECRETS_PATH/*" {
  capabilities = ["create", "update", "delete", "read", "list"]
}
EOF

echo creating vault policy policy-$OPERATOR_ACCESS_LEVEL.hcl

vault policy write secret-$OPERATOR_ACCESS_LEVEL policy-$OPERATOR_ACCESS_LEVEL.hcl

# create policy write
cat << EOF > policy-write.hcl
path "$SECRETS_PATH/*" {
  capabilities = ["create", "update", "delete"]
}
EOF

echo creating vault policy policy-write.hcl

vault policy write secret-write-only policy-write.hcl

# create auth token
export VAULT_TOKEN_OPERATOR=$(vault token create -policy=secret-$OPERATOR_ACCESS_LEVEL -ttl=30d -field token)

echo creating secret with token for humanitec operator
# create a secret with the token
oc create secret generic vault-token \
    -n humanitec-operator-system \
    --from-literal=token=${VAULT_TOKEN_OPERATOR}

### if needed to update the token (after 30d), 
### create the new token with the previous command and update the secret
###
# oc patch secret vault-token \
#   -n humanitec-operator-system \
#   --patch="{\"data\": { \"token\": \"$(echo -n $VAULT_TOKEN_OPERATOR | base64 -w0)\"}}"
###

echo creating humanitec operator vault token SecretStore ${SECRET_STORE_ID} as default store
# create the SecretStore to attach the operator to the Secret
oc apply -n humanitec-operator-system -f - << EOF
apiVersion: humanitec.io/v1alpha1
kind: SecretStore
metadata:
  name: ${SECRET_STORE_ID}
  namespace: humanitec-operator-system
  labels:
    app.humanitec.io/default-store: "true"
spec:
  vault:
    url: ${VAULT_ADDR}
    path: ${SECRETS_PATH}
    auth:
      tokenSecretRef:
        name: vault-token
        key: token
EOF

echo confirm it was created
oc get secretstores -n humanitec-operator-system

# create orq token
export VAULT_TOKEN_ORCHESTRATOR=$(vault token create -policy=secret-write-only -ttl=30d -field token)

echo creating humanitec orquestrator vault token
# register secret store in orq
humctl api post /orgs/${HUMANITEC_ORG}/secretstores \
  -d '{
  "id": "'${SECRET_STORE_ID}'",
  "primary": false,
  "vault": {
    "url": "'${VAULT_ADDR}'",
    "path": "'${SECRETS_PATH}'",
    "auth": {
      "token": "'${VAULT_TOKEN_ORCHESTRATOR}'"
    }
  }
}'
echo orq vault token registration humctl api call exit code=$?

### if needed to update the token (after 30d), 
### create the new token with the previous command and update the orq
###
# humctl api patch /orgs/${HUMANITEC_ORG}/secretstores/${SECRET_STORE_ID} \
#   -d '{
#   "vault": {
#     "auth": {
#       "token": "'${VAULT_TOKEN_ORCHESTRATOR}'"
#     }
#   }
# }'
###

echo check if the hashicorp vault on openshift secret store is created
humctl api get /orgs/${HUMANITEC_ORG}/secretstores

echo done

