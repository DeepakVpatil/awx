#!/bin/bash

# AWX Local Deployment Script for Docker Desktop Kubernetes
# Usage: ./deploy-local.sh

set -e

echo "🚀 Starting AWX local deployment on Docker Desktop Kubernetes..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if Docker Desktop Kubernetes is running
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Kubernetes cluster not accessible. Please enable Kubernetes in Docker Desktop."
    exit 1
fi

# Check if Helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ Helm not found. Please install Helm first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Create namespace
echo "📁 Creating AWX namespace..."
kubectl create namespace awx --dry-run=client -o yaml | kubectl apply -f -

# Add AWX operator Helm repository
echo "📦 Adding AWX operator Helm repository..."
helm repo add awx-operator https://ansible.github.io/awx-operator/
helm repo update

# Create local values file for Docker Desktop
echo "⚙️ Creating local configuration..."
cat > values-local.yaml << EOF
# Local Docker Desktop Configuration
replicaCount: 1

image:
  repository: quay.io/ansible/awx-operator
  pullPolicy: IfNotPresent
  tag: "2.19.1"

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

AWX:
  enabled: true
  name: awx-local
  spec:
    service_type: NodePort
    web_resource_requirements:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        cpu: 500m
        memory: 1Gi
    task_resource_requirements:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        cpu: 500m
        memory: 1Gi
    postgres_resource_requirements:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        cpu: 200m
        memory: 512Mi
    postgres_storage_requirements:
      requests:
        storage: 2Gi
    projects_persistence: true
    projects_storage_size: 1Gi
EOF

# Install AWX operator
echo "🔧 Installing AWX operator..."
helm install awx-operator awx-operator/awx-operator \
  -n awx \
  -f values-local.yaml

# Wait for operator to be ready
echo "⏳ Waiting for AWX operator to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/awx-operator-controller-manager -n awx

# Create AWX instance
echo "🎯 Creating AWX instance..."
cat > awx-instance-local.yaml << EOF
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-local
  namespace: awx
spec:
  service_type: NodePort
  web_replicas: 1
  task_replicas: 1
  postgres_storage_class: hostpath
  postgres_storage_requirements:
    requests:
      storage: 2Gi
  projects_persistence: true
  projects_storage_class: hostpath
  projects_storage_size: 1Gi
  web_resource_requirements:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 1Gi
  task_resource_requirements:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 1Gi
  postgres_resource_requirements:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 200m
      memory: 512Mi
EOF

kubectl apply -f awx-instance-local.yaml

# Wait for AWX instance to be ready
echo "⏳ Waiting for AWX instance to be ready (this may take 5-10 minutes)..."
kubectl wait --for=condition=Running --timeout=600s awx/awx-local -n awx

# Get service information
echo "📊 Getting service information..."
kubectl get svc -n awx

# Get admin password
echo "🔑 Getting admin password..."
ADMIN_PASSWORD=$(kubectl get secret awx-local-admin-password -n awx -o jsonpath="{.data.password}" | base64 --decode)

echo ""
echo "🎉 AWX local deployment completed successfully!"
echo ""
echo "📋 Access Information:"
echo "===================="
echo "Username: admin"
echo "Password: $ADMIN_PASSWORD"
echo ""
echo "🌐 Access Methods:"
echo "1. Port Forward (Recommended):"
echo "   kubectl port-forward svc/awx-local-service -n awx 8080:80"
echo "   Then open: http://localhost:8080"
echo ""
echo "2. NodePort:"
NODEPORT=$(kubectl get svc awx-local-service -n awx -o jsonpath='{.spec.ports[0].nodePort}')
echo "   Direct access: http://localhost:$NODEPORT"
echo ""
echo "🔍 Useful Commands:"
echo "Check status: kubectl get awx -n awx"
echo "View pods: kubectl get pods -n awx"
echo "View logs: kubectl logs -l app.kubernetes.io/name=awx -n awx"
echo ""
echo "🧹 Cleanup (when done):"
echo "helm uninstall awx-operator -n awx"
echo "kubectl delete namespace awx"