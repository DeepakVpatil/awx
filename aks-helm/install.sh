#!/bin/bash

# Create Helm chart if not exists
if [ ! -d "awx-operator-chart" ]; then
  ./download-chart.sh
fi

# Create namespace
kubectl create namespace awx

# Install AWX using local Helm chart
helm install awx-operator ./awx-operator-chart -n awx -f values.yaml


# Wait for operator to be ready
kubectl wait --for=condition=available --timeout=300s deployment/awx-operator-controller-manager -n awx

# Wait for AWX instance to be ready (deployed by Helm chart)
echo "Waiting for AWX instance to be ready..."
kubectl wait --for=condition=Running --timeout=600s awx/awx -n awx

echo "AWX installation completed. Check status with:"
echo "kubectl get awx -n awx"
echo "kubectl get pods -n awx"