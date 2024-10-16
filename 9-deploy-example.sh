#!/bin/bash
# create and deploy a test application
# https://developer.humanitec.com/integration-and-extensions/humanitec-agent/how-tos/deploy-to-a-private-cluster-using-the-humanitec-agent/
set -euo pipefail

echo creating app in humanitec orquestrator

humctl create application luiz-agent-app

echo create app humctl return code: $?

echo create an environment to match with new cluster

humctl api POST /orgs/${HUMANITEC_ORG}/apps/luiz-agent-app/envs \
  --fail \
  -d '{ 
    "id":"'${K8S_DEFINITION_ID}'", 
    "name":"'${K8S_DEFINITION_ID}'", 
    "type":"development" 
  }'

echo create env humctl exit code=$?

cat <<EOF > score-busybox.yaml
apiVersion: score.dev/v1b1
metadata:
  name: test-app
containers:
  test-app:
    image: busybox:latest
    command: ["/bin/sh"]
    args: ["-c", "while true; do printenv && sleep 99999; done"]
EOF

echo deploy application to new cluster

humctl score deploy -f score-busybox.yaml \
  --app luiz-agent-app \
  --env ${K8S_DEFINITION_ID}

echo deploy app humctl return code: $?

echo done

