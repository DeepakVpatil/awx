#!/bin/bash

echo "Starting local AWX deployment..."

# Create Helm chart if not exists
if [ ! -d "awx-operator-chart" ]; then
  echo "Downloading Helm chart..."
  ./download-chart.sh
fi

# Create namespace
echo "Creating namespace..."
kubectl create namespace awx --dry-run=client -o yaml | kubectl apply -f -

# Install AWX using local configuration
echo "Installing AWX operator with local configuration..."
helm install awx-operator ./awx-operator-chart \
  -n awx \
  -f values-local.yaml

# Wait for operator to be ready
echo "Waiting for operator to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/awx-operator-controller-manager -n awx

# Wait for AWX instance to be ready
echo "Waiting for AWX instance to be ready..."
kubectl wait --for=condition=Running --timeout=600s awx/awx-local -n awx

echo ""
echo "AWX local deployment completed!"
echo ""
echo "Access methods:"
echo "1. Port forward: kubectl port-forward svc/awx-local-service -n awx 8080:80"
echo "2. NodePort: kubectl get svc -n awx (check NodePort)"
echo ""
echo "Get admin password:"
echo "kubectl get secret awx-local-admin-password -n awx -o jsonpath='{.data.password}' | base64 --decode"
echo ""
echo "Check status:"
echo "kubectl get awx -n awx"
echo "kubectl get pods -n awx"