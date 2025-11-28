# Local AWX Deployment Guide

Deploy AWX on local Kubernetes clusters for development and testing.

## Local Kubernetes Options

### Option 1: Docker Desktop (Recommended)

#### Prerequisites
- Docker Desktop with Kubernetes enabled
- 8GB+ RAM allocated to Docker Desktop
- kubectl and Helm installed

#### Setup
```bash
# Enable Kubernetes in Docker Desktop
# Settings > Kubernetes > Enable Kubernetes

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

### Option 2: Minikube

#### Prerequisites
```bash
# Install minikube
# Windows: choco install minikube
# macOS: brew install minikube
# Linux: curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Start minikube with sufficient resources
minikube start --cpus=4 --memory=8192 --disk-size=20g
minikube addons enable ingress
```

### Option 3: Kind (Kubernetes in Docker)

#### Setup
```bash
# Install kind
# Windows: choco install kind
# macOS: brew install kind
# Linux: curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64

# Create cluster
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
EOF
```

## Local Deployment Methods

### Method 1: Quick Local Deploy

```bash
# Clone repository
git clone <repository-url>
cd awx

# Deploy with default settings
./deploy-awx.sh

# Access AWX
kubectl port-forward svc/awx-service -n awx 8080:80
# Open browser: http://localhost:8080
```

### Method 2: Customized Local Deploy

#### Step 1: Setup Local Configuration

Create `awx/aks-helm/values-local.yaml`:

```yaml
# Local Development Configuration
replicaCount: 1

image:
  repository: quay.io/ansible/awx-operator
  pullPolicy: IfNotPresent
  tag: "2.19.1"

# Reduced resources for local development
resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

# AWX Configuration for local
AWX:
  enabled: true
  name: awx-local
  spec:
    service_type: NodePort
    # Reduced resources for local development
    web_resource_requirements:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 1Gi
    task_resource_requirements:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 1Gi
    
  # Use local PostgreSQL
  postgres:
    enabled: true
```

#### Step 2: Deploy with Local Configuration

```bash
cd aks-helm

# Download chart
./download-chart.sh

# Deploy with local values
helm install awx-operator ./awx-operator-chart \
  -n awx \
  --create-namespace \
  -f values-local.yaml

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s deployment/awx-operator-controller-manager -n awx
```

## Local Access Methods

### Port Forward (All Platforms)

```bash
# Get AWX service
kubectl get svc -n awx

# Port forward
kubectl port-forward svc/awx-local-service -n awx 8080:80

# Access: http://localhost:8080
```

### NodePort (Docker Desktop/Minikube)

```bash
# Get NodePort
kubectl get svc -n awx -o wide

# For Docker Desktop: http://localhost:<nodeport>
# For Minikube: minikube service awx-local-service -n awx --url
```

### Ingress (Advanced)

Create `awx-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: awx-ingress
  namespace: awx
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: awx.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: awx-local-service
            port:
              number: 80
```

```bash
# Apply ingress
kubectl apply -f awx-ingress.yaml

# Add to /etc/hosts (Linux/macOS) or C:\Windows\System32\drivers\etc\hosts (Windows)
echo "127.0.0.1 awx.local" >> /etc/hosts

# Access: http://awx.local
```

## Local Development Tips

### Resource Optimization

```yaml
# Minimal resource configuration for local development
resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 50m
    memory: 64Mi

AWX:
  spec:
    # Disable resource-intensive features for local
    web_replicas: 1
    task_replicas: 1
```

### Persistent Storage

```bash
# Check storage classes
kubectl get storageclass

# For local development, use default storage class
# Data persists across pod restarts but not cluster recreation
```

### Local Registry (Optional)

```bash
# For testing custom images locally
docker run -d -p 5000:5000 --name registry registry:2

# Tag and push local images
docker tag your-awx-operator:latest localhost:5000/awx-operator:latest
docker push localhost:5000/awx-operator:latest

# Update values.yaml
image:
  repository: localhost:5000/awx-operator
  tag: latest
```

## Troubleshooting Local Issues

### Common Problems

```bash
# Insufficient resources
kubectl describe nodes
kubectl top nodes
kubectl top pods -n awx

# Storage issues
kubectl get pv
kubectl get pvc -n awx
kubectl describe pvc -n awx

# Network issues
kubectl get svc -n awx
kubectl get endpoints -n awx
```

### Reset Local Environment

```bash
# Complete cleanup
helm uninstall awx-operator -n awx
kubectl delete namespace awx
kubectl delete pv --all  # Caution: removes all persistent volumes

# For minikube
minikube delete
minikube start --cpus=4 --memory=8192

# For kind
kind delete cluster
```

## Performance Considerations

### Minimum Requirements
- **CPU**: 2 cores
- **RAM**: 4GB available to Kubernetes
- **Storage**: 10GB free space

### Recommended for Development
- **CPU**: 4 cores
- **RAM**: 8GB available to Kubernetes
- **Storage**: 20GB free space

### Docker Desktop Settings
```bash
# Recommended Docker Desktop resource allocation
# Settings > Resources > Advanced
# CPUs: 4
# Memory: 8GB
# Swap: 2GB
# Disk image size: 64GB
```

## Local Testing Workflow

1. **Deploy AWX locally**
2. **Create test projects and inventories**
3. **Test playbook execution**
4. **Validate configurations**
5. **Export/backup configurations for production**

This local deployment approach allows for rapid development and testing before deploying to production environments.

## Troubleshooting

For common local deployment issues (port binding, driver problems, resource constraints), see:
- **File**: `awx/TROUBLESHOOTING-LOCAL.md`
- Covers Windows-specific issues, alternative solutions, and quick fixes