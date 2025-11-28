# AWX Installation Guide

Comprehensive AWX deployment using Helm charts with customization options.

## Prerequisites

- kubectl configured for target Kubernetes cluster
- Helm >= 3.0
- Git (for chart download)

## Installation Methods

### Method 1: Quick Deploy (Root Directory)

```bash
# Simple deployment with default settings
./deploy-awx.sh
```

**File**: `awx/deploy-awx.sh`

### Method 2: Customizable Helm Chart (Recommended)

#### Step 1: Download Helm Chart

```bash
cd aks-helm
./download-chart.sh
```

**File**: `awx/aks-helm/download-chart.sh`

#### Step 2: Customize Configuration

Edit `awx/aks-helm/values.yaml` for company-specific settings:

```yaml
# Example customizations
image:
  repository: "your-company-registry/awx-operator"
  tag: "2.19.1-company"

serviceAccount:
  name: "company-awx-operator"
  annotations:
    company.com/owner: "platform-team"

resources:
  limits:
    cpu: "1000m"
    memory: "1Gi"

AWX:
  enabled: true
  name: company-awx
  spec:
    service_type: LoadBalancer
```

**File**: `awx/aks-helm/values.yaml`

#### Step 3: Deploy AWX

```bash
./install.sh
```

**File**: `awx/aks-helm/install.sh`

## File Structure

```
awx/
├── deploy-awx.sh                    # Quick deployment script
├── aks-helm/
│   ├── values.yaml                  # Main configuration file
│   ├── install.sh                   # Customizable installation
│   ├── download-chart.sh            # Chart download script
│   └── awx-operator-chart/          # Helm chart directory
└── COMPANY-CUSTOMIZATION.md         # Customization guide
```

## Verification

```bash
# Check AWX operator status
kubectl get pods -n awx -l control-plane=controller-manager

# Check AWX instance status
kubectl get awx -n awx

# Check all AWX pods
kubectl get pods -n awx

# View AWX logs
kubectl logs -n awx -l app.kubernetes.io/name=awx
```

## Access AWX

### Get Admin Credentials

```bash
# Get admin password
kubectl get secret awx-admin-password -n awx -o jsonpath="{.data.password}" | base64 --decode

# Get admin username (usually 'admin')
kubectl get secret awx-admin-password -n awx -o jsonpath="{.data.username}" | base64 --decode
```

### Access Methods

#### Port Forward (Development)

```bash
# Port forward to access UI
kubectl port-forward svc/awx-service -n awx 8080:80

# Access via browser: http://localhost:8080
```

#### LoadBalancer (Production)

```bash
# Get external IP (if using LoadBalancer service type)
kubectl get svc -n awx

# Access via external IP on port 80
```

## Company Customization

For company-specific configurations, see:
- **File**: `awx/COMPANY-CUSTOMIZATION.md`
- Covers private registries, security policies, resource limits
- Node selection and company labeling standards

## Troubleshooting

### Common Issues

```bash
# Check operator logs
kubectl logs -n awx deployment/awx-operator-controller-manager

# Check AWX instance events
kubectl describe awx awx -n awx

# Check persistent volume claims
kubectl get pvc -n awx

# Restart AWX operator
kubectl rollout restart deployment/awx-operator-controller-manager -n awx
```

### Resource Requirements

- **Minimum**: 2 CPU cores, 4GB RAM
- **Recommended**: 4 CPU cores, 8GB RAM
- **Storage**: 20GB for PostgreSQL data

## Cleanup

### Remove AWX Instance Only

```bash
kubectl delete awx awx -n awx
```

### Complete Removal

```bash
# Remove Helm release
helm uninstall awx-operator -n awx

# Delete namespace
kubectl delete namespace awx

# Remove CRDs (optional)
kubectl delete crd awxs.awx.ansible.com
kubectl delete crd awxbackups.awx.ansible.com
kubectl delete crd awxrestores.awx.ansible.com
```

## Support

- **AWX Documentation**: https://ansible.readthedocs.io/projects/awx/
- **Operator Documentation**: https://ansible.readthedocs.io/projects/awx-operator/
- **Helm Chart Issues**: Check `awx/aks-helm/awx-operator-chart/` for templates