# attach the cluster to the agent
# https://developer.humanitec.com/integration-and-extensions/humanitec-agent/how-tos/deploy-to-a-private-cluster-using-the-humanitec-agent/
set -euo pipefail

echo attaching k8s cluster to the agent

humctl api PATCH /orgs/${HUMANITEC_ORG}/resources/defs/${K8S_DEFINITION_ID} -d '{
  "name": "'${K8S_DEFINITION_NAME}'",
  "driver_inputs": {
    "secrets": {
      "agent_url": "\${resources['agent#\${AGENT_ID}'].outputs.url}"
    }
  }
}'
echo attach k8s and agent humctl api call exit code=$?

echo ATTENTION: please double check in the output above if the value is as it is meant to be: "\${resources['agent#\${AGENT_ID}'].outputs.url}"

echo done
