#!/bin/bash

# Prerequisites: kubectl configured for target cluster

# Add AWX Operator Helm repository
    helm repo add awx-operator https://ansible-community.github.io/awx-operator-helm/
helm repo update

# Deploy AWX Operator
helm install awx-operator awx-operator/awx-operator \
  --namespace awx \
  --create-namespace \
  --version 2.19.1

# Wait for operator to be ready
kubectl wait --for=condition=available --timeout=300s deployment/awx-operator-controller-manager -n awx

# Create AWX instance
kubectl apply -f - <<EOF
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  service_type: ClusterIP
EOF

echo "AWX deployment complete. Check status with: kubectl get awx -n awx"