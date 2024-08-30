# install humanitec-operator
# https://developer.humanitec.com/integration-and-extensions/humanitec-operator/installation/
set -euo pipefail

echo installing humanitec-operator with helm

helm install humanitec-operator \
  oci://ghcr.io/humanitec/charts/humanitec-operator \
  --namespace humanitec-operator-system \
  --create-namespace

oc get pods -n humanitec-operator-system

echo done

