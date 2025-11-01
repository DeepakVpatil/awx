#!/bin/bash

# Add AWX Helm repository
helm repo add awx-operator https://ansible.github.io/awx-operator/
helm repo update

# Create namespace
kubectl create namespace awx

# Install AWX using Helm
helm install awx-operator awx-operator/awx-operator -n awx

# Wait for operator to be ready
kubectl wait --for=condition=available --timeout=300s deployment/awx-operator-controller-manager -n awx

# Apply AWX instance
kubectl apply -f - <<EOF
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  service_type: LoadBalancer
EOF

echo "AWX installation completed. Check status with:"
echo "kubectl get awx -n awx"