# generate certificates and user to be used by humanitec orquestrator to connect to the cluster
# these activities are in the pre-reqs
# https://developer.humanitec.com/integration-and-extensions/containerization/kubernetes/
set -euo pipefail

echo username to be used: ${USR_NAME}

echo generating ${KEY_FILE}
openssl genrsa -out ${KEY_FILE} 2048
echo generating ${CSR_FILE}
openssl req -new -key ${KEY_FILE} -out ${CSR_FILE} -subj "/CN=${USR_NAME}"

echo sending certificate sign request
cat <<EOF | oc apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${USR_NAME}
spec:
  request: $(cat ${CSR_FILE} | base64 | tr -d "\n")
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: ${CRT_EXP_SEC} 
  usages:
  - client auth
EOF

echo verifying cert:
oc get csr | grep ${USR_NAME}

echo approving cert
oc adm certificate approve ${USR_NAME}

echo exporting cert
oc get csr ${USR_NAME} -o jsonpath='{.status.certificate}'| base64 -d > ${CRT_FILE}

echo make sure expiration date works for you:
openssl x509 -inform pem -noout -text -in ${CRT_FILE} | grep 'Not After'

echo adding policy of cluster admin to ${USR_NAME} ( ignore user not found warning )
oc adm policy add-cluster-role-to-user cluster-admin ${USR_NAME}
#oc create rolebinding ${USR_NAME}-admin-binding --clusterrole=cluster-admin --user=${USR_NAME}
# maybe try with self-provisioner role?
# to troubleshoot: https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#add-to-kubeconfig

echo done
