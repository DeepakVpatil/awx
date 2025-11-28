# AWX on Docker Desktop Kubernetes

Quick guide to deploy AWX on Docker Desktop with Kubernetes enabled.

## Prerequisites

### 1. Docker Desktop Setup
- Install Docker Desktop
- Enable Kubernetes: Settings → Kubernetes → Enable Kubernetes
- Allocate resources: Settings → Resources → Advanced
  - **CPUs**: 4 (minimum 2)
  - **Memory**: 8GB (minimum 4GB)
  - **Swap**: 2GB
  - **Disk**: 64GB

### 2. Required Tools
```bash
# Install kubectl (if not included with Docker Desktop)
# Windows (Chocolatey)
choco install kubernetes-cli

# Install Helm
# Windows (Chocolatey)
choco install kubernetes-helm

# Verify installations
kubectl version --client
helm version --short
```

## Quick Deployment

### Option 1: Automated Script (Recommended)

**Windows:**
```cmd
deploy-local.bat
```

**Linux/macOS:**
```bash
chmod +x deploy-local.sh
./deploy-local.sh
```

### Option 2: Manual Steps

```bash
# 1. Create namespace
kubectl create namespace awx

# 2. Add Helm repository
helm repo add awx-operator https://ansible.github.io/awx-operator/
helm repo update

# 3. Install AWX operator
helm install awx-operator awx-operator/awx-operator -n awx

# 4. Create AWX instance
cat <<EOF | kubectl apply -f -
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-local
  namespace: awx
spec:
  service_type: NodePort
  web_replicas: 1
  task_replicas: 1
  postgres_storage_requirements:
    requests:
      storage: 2Gi
  projects_persistence: true
  projects_storage_size: 1Gi
EOF

# 5. Wait for deployment
kubectl wait --for=condition=Running --timeout=600s awx/awx-local -n awx
```

## Access AWX

### Get Admin Credentials
```bash
# Username: admin
# Password:
kubectl get secret awx-local-admin-password -n awx -o jsonpath="{.data.password}" | base64 --decode
```

### Access Methods

**Method 1: Port Forward (Recommended)**
```bash
kubectl port-forward svc/awx-local-service -n awx 8080:80
# Open browser: http://localhost:8080
```

**Method 2: NodePort**
```bash
# Get NodePort
kubectl get svc awx-local-service -n awx
# Access via: http://localhost:<nodeport>
```

## Verification

```bash
# Check deployment status
kubectl get awx -n awx
kubectl get pods -n awx
kubectl get svc -n awx

# View logs
kubectl logs -l app.kubernetes.io/name=awx -n awx
```

## Resource Usage

### Minimal Configuration
- **Pods**: 3-4 (operator, web, task, postgres)
- **CPU**: ~300m total
- **Memory**: ~1.5Gi total
- **Storage**: ~3Gi total

### Monitoring Resources
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n awx

# Check storage
kubectl get pv
kubectl get pvc -n awx
```

## Troubleshooting

### Common Issues

**1. Insufficient Resources**
```bash
# Check Docker Desktop resource allocation
# Increase memory to 8GB minimum
```

**2. Pods Stuck in Pending**
```bash
kubectl describe pod <pod-name> -n awx
# Usually indicates resource constraints
```

**3. Storage Issues**
```bash
kubectl get pvc -n awx
kubectl describe pvc -n awx
# Check if PVs are bound
```

**4. Service Not Accessible**
```bash
kubectl get svc -n awx
kubectl get endpoints -n awx
# Verify service endpoints
```

### Reset Environment
```bash
# Complete cleanup
helm uninstall awx-operator -n awx
kubectl delete namespace awx
kubectl delete pv --all  # Caution: removes all PVs

# Restart Docker Desktop if needed
```

## Development Tips

### Custom Configuration
Create `values-custom.yaml`:
```yaml
AWX:
  spec:
    # Custom admin password
    admin_password_secret: custom-admin-secret
    
    # Custom resource limits
    web_resource_requirements:
      limits:
        cpu: 1000m
        memory: 2Gi
    
    # Enable ingress
    ingress_type: ingress
    hostname: awx.local
```

### Persistent Data
- AWX data persists across pod restarts
- Data is lost when namespace is deleted
- For permanent storage, use external PostgreSQL

### Performance Optimization
```yaml
# Reduce resource usage for development
AWX:
  spec:
    web_replicas: 1
    task_replicas: 1
    web_resource_requirements:
      requests:
        cpu: 50m
        memory: 128Mi
```

## Next Steps

1. **Create Projects**: Import your Ansible playbooks
2. **Setup Inventories**: Define your target hosts
3. **Configure Credentials**: Add SSH keys, cloud credentials
4. **Run Job Templates**: Execute your automation

## Cleanup

```bash
# Remove AWX
helm uninstall awx-operator -n awx
kubectl delete namespace awx

# Optional: Remove persistent volumes
kubectl delete pv --all
```

This setup provides a fully functional AWX instance for local development and testing.