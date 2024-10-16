#!/bin/bash
# install humanitec agent
# it is possible to install via helm, but using manifests as some changes are needed due to ocp arq
# https://developer.humanitec.com/integration-and-extensions/humanitec-agent/installation/
set -euo pipefail

echo installing humatenic agent on ocp
echo WARNING: this has been created on mac, please open the file and make the described change on linux.
echo TODO: make the parameter to be set automatically based on environment

oc new-project humanitec-agent

oc apply -n humanitec-agent -f - <<EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: humanitec-agent
  labels:
    app.kubernetes.io/name: "humanitec-agent"
    app.kubernetes.io/instance: "humanitec-agent"
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: humanitec-agent
  namespace: humanitec-agent
  labels:
    app.kubernetes.io/name: "humanitec-agent"
    app.kubernetes.io/instance: "humanitec-agent"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: humanitec-agent-scc
  namespace: humanitec-agent
  labels:
    app.kubernetes.io/name: "humanitec-agent"
    app.kubernetes.io/instance: "humanitec-agent"
subjects:
  - kind: ServiceAccount
    name: humanitec-agent
    namespace: humanitec-agent
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
# review these priviledge scc 
  name: system:openshift:scc:privileged
---
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: humanitec-agent
  name: humanitec-agent-configmap-env
  labels:
    app.kubernetes.io/name: "humanitec-agent"
    app.kubernetes.io/instance: "humanitec-agent"
data:
  ORGS: ${HUMANITEC_ORG}
---
apiVersion: v1
kind: Secret
metadata:
  name: humanitec-agent-secret-private-key
  namespace: humanitec-agent
  labels:
    app.kubernetes.io/name: "humanitec-agent"
    app.kubernetes.io/instance: "humanitec-agent"
data:
#on mac omit -w0 from base64 command below
  private_key: |
    $(cat humanitec_agent_private_key.pem | base64 )
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: humanitec-agent
  name: humanitec-agent
  labels:
    app.kubernetes.io/name: "humanitec-agent"
    app.kubernetes.io/instance: "humanitec-agent"
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: "humanitec-agent"
      app.kubernetes.io/instance: "humanitec-agent"
  template:
    metadata:
      labels:
        app.kubernetes.io/name: "humanitec-agent"
        app.kubernetes.io/instance: "humanitec-agent"
    spec:
      serviceAccountName: humanitec-agent
      securityContext:
        fsGroup: 1000
        fsGroupChangePolicy: Always
        runAsGroup: 1000
        runAsUser: 1000
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: humanitec-agent
          image: "ghcr.io/humanitec/agent:1.8.1"
          resources:
            limits:
              cpu: "0.250"
              memory: 256Mi
            requests:
              cpu: "0.025"
              memory: 64Mi
          securityContext:
# review these priviledge scc
            allowPrivilegeEscalation: true
            capabilities:
              drop:
                - ALL
# review these priviledge scc               
            privileged: true
            readOnlyRootFilesystem: true
          env:
          - name: CONNECTION_ID
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          envFrom:
          - configMapRef:
              name: humanitec-agent-configmap-env
          volumeMounts:
          - name: agentmount
            mountPath: "/keys"
            readOnly: true
      serviceAccount: humanitec-agent
      volumes:
      - name: agentmount
        projected:
          sources:
          - secret:
              name: humanitec-agent-secret-private-key
              items:
                - key: private_key
                  path: private_key.pem
                  mode: 384 #equivalent of 0600
EOF

oc get pods -n humanitec-agent

echo use bellow command to get the logs:
echo oc logs -n humanitec-agent deployment/humanitec-agent

echo WARNING: this has been created on mac, please open the file and make the described change on linux.
echo TODO: make the parameter to be set automatically based on environment

echo done

