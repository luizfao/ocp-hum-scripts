# create the cluster and register
# https://developer.humanitec.com/integration-and-extensions/containerization/kubernetes/
set -euo pipefail

echo create humanitec cluster

cat <<EOF > ./${K8S_DEFINITION_ID}-cluster.yaml
# Resource Definition for a generic Kubernetes cluster
apiVersion: entity.humanitec.io/v1b1
kind: Definition
metadata:
  id: ${K8S_DEFINITION_ID}
entity:
  name: ${K8S_DEFINITION_ID}
  type: k8s-cluster
  driver_type: humanitec/k8s-cluster
  driver_inputs:
    values:
#      name: my-generic-k8s-cluster
#      loadbalancer: 35.10.10.10
      cluster_data:
        insecure-skip-tls-verify: true
        server: ${CLUSTER_API}
        # Single line base64-encoded cluster CA data in the format "LS0t...ca-data....=="
#        certificate-authority-data: 
    secrets:
      credentials:
        # Single line base64-encoded client certificate data in the format "LS0t...cert-data...=="
        client-certificate-data: $(cat ${CRT_FILE} | base64 | tr -d "\n")
        # Single line base64-encoded client key data in the format "LS0t...key-data...=="
        client-key-data: $(cat ${KEY_FILE} | base64 | tr -d "\n")
EOF

humctl apply -f ./${K8S_DEFINITION_ID}-cluster.yaml
echo create cluster humctl exit code=$?

# add an criteria to the cluster
#humctl api post /orgs/$HUMANITEC_ORG/resources/defs/${K8S_DEFINITION_ID}/criteria \
#-d '{ 
#  "env_id": "ocp" 
#}'
#echo add criteria humctl exit code=$?


