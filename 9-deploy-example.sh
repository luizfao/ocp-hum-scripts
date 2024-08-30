# create and deploy a test application
# https://developer.humanitec.com/integration-and-extensions/humanitec-agent/how-tos/deploy-to-a-private-cluster-using-the-humanitec-agent/
set -euo pipefail

echo creating app in humanitec orquestrator
humctl create application luiz-agent-app
echo create app humctl return code: $?

echo deploying application

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

humctl score deploy -f score-busybox.yaml \
  --app luiz-agent-app \
  --env development
echo deploy app humctl return code: $?

#echo add ocp environment to the app
# curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/apps/test-app/envs" \
#   -X POST \
#   -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
#   -H "Content-Type: application/json" \
#   -d '{"id": "ocp","name": "ocp","type": "development"}'
# echo create app env humanitec api call return code: $?

echo done

