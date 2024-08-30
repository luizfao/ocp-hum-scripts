# install agent 
# https://developer.humanitec.com/integration-and-extensions/humanitec-agent/installation/
set -euo pipefail

# Generate the private key in humanitec_agent_private_key.pem
echo generating humanitec agent private key
openssl genrsa -out humanitec_agent_private_key.pem 4096

# Generate public key from the private key in humanitec_agent_public_key.pem
echo generating humanitec agent public key
openssl rsa -in humanitec_agent_private_key.pem -outform PEM -pubout -out humanitec_agent_public_key.pem

echo creating agent ${AGENT_ID}.yaml
cat << EOF > ${AGENT_ID}.yaml
apiVersion: entity.humanitec.io/v1b1
kind: Definition
metadata:
  id: ${AGENT_ID}
entity:
  type: agent
  name: ${AGENT_ID}
  driver_type: humanitec/agent
  driver_inputs:
    values:
      id: ${AGENT_ID}
  criteria:
  - env_type: development
    res_id: agent
EOF

humctl apply -f ${AGENT_ID}.yaml
echo create agent humctl exit code=$?

humctl api POST /orgs/${HUMANITEC_ORG}/agents \
  -d '{
  "id": "'${AGENT_ID}'",
  "public_key": '"$(cat humanitec_agent_public_key.pem | jq -sR)"',
  "description": "Demo Agent"
}'
echo add key humctl api call exit code=$?

# add criteria to the agent
#humctl api post /orgs/$HUMANITEC_ORG/resources/defs/${AGENT_ID}/criteria \
#-d '{
#"env_id": "ocp"
#}'
#echo add criteria env_id: luiz-ocp humctl api call exit code=$?

echo done

