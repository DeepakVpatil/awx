# AWX on Kubernetes Deployment

Production-ready AWX (Ansible Web UI) deployment on Kubernetes using Helm charts with enterprise customization support.

## Overview

This repository provides a streamlined approach to deploy AWX on Kubernetes clusters, specifically optimized for Azure Kubernetes Service (AKS) with comprehensive customization options for enterprise environments.

## Deployment Method

### Helm Chart Deployment (`aks-helm/`)
- **Method**: Official AWX Operator Helm Chart
- **Infrastructure**: Any Kubernetes cluster (AKS optimized)
- **Deployment**: `./aks-helm/install.sh`
- **Best for**: Production deployments with customization

## Quick Start

### Prerequisites
- kubectl configured for target Kubernetes cluster
- Helm >= 3.0
- Azure CLI (for AKS)

### Simple Deployment
```bash
# Quick deployment with defaults
./deploy-awx.sh
```

### Customized Deployment (Recommended)
```bash
# Navigate to Helm directory
cd aks-helm

# Download Helm chart
./download-chart.sh

# Customize configuration (optional)
# Edit values.yaml for company-specific settings

# Deploy AWX
./install.sh
```

## Repository Structure

```
├── aks-helm/                   # Helm chart deployment (main method)
│   ├── awx-operator-chart/     # Downloaded Helm chart
│   ├── values.yaml             # Main configuration
│   ├── values-local.yaml       # Local development config
│   ├── install.sh              # Installation script
│   ├── install-local.sh        # Local installation script
│   └── download-chart.sh       # Chart download script
├── deploy-awx.sh               # Quick deployment script
├── INSTALLATION.md             # Detailed installation guide
├── AKS-DEPLOYMENT-STEPS.md     # Step-by-step AKS deployment
├── COMPANY-CUSTOMIZATION.md    # Enterprise customization guide
└── README.md                   # This file
```

## Configuration Files

- **`aks-helm/values.yaml`**: Main configuration with company customization examples
- **`aks-helm/values-local.yaml`**: Local development configuration
- **`deploy-awx.sh`**: Simple deployment script
- **`aks-helm/install.sh`**: Full deployment with customization

## Enterprise Features

### Company Customization
- Private container registry support
- Custom security contexts and RBAC
- Resource limits and node placement
- Company-specific annotations and labels
- Environment variables for integration

### Security
- Non-root container execution
- Read-only root filesystem
- Capability dropping
- Custom UID/GID ranges

### High Availability
- Multi-replica operator deployment
- Pod anti-affinity rules
- Resource requests and limits
- Health checks and monitoring

## Documentation

- **[INSTALLATION.md](INSTALLATION.md)**: Complete installation guide
- **[AKS-DEPLOYMENT-STEPS.md](AKS-DEPLOYMENT-STEPS.md)**: Step-by-step AKS deployment
- **[COMPANY-CUSTOMIZATION.md](COMPANY-CUSTOMIZATION.md)**: Enterprise customization guide

## Getting Started

### 1. AKS Setup (if needed)
```bash
# Login to Azure
az login
az account set --subscription "your-subscription-id"

# Get AKS credentials
az aks get-credentials --resource-group your-rg --name your-aks
```

### 2. Deploy AWX
```bash
# Clone repository
git clone <repository-url>
cd awx

# Quick deployment
./deploy-awx.sh

# OR customized deployment
cd aks-helm
./download-chart.sh
./install.sh
```

### 3. Access AWX
```bash
# Get admin password
kubectl get secret awx-admin-password -n awx -o jsonpath="{.data.password}" | base64 --decode

# Access methods:
# 1. Port forward: kubectl port-forward svc/awx-service -n awx 8080:80
# 2. LoadBalancer: kubectl get svc -n awx (get external IP)

# Login: http://localhost:8080 or http://<external-ip>
# Username: admin, Password: (from above command)
```

## Customization

For enterprise deployments, customize `aks-helm/values.yaml`:

```yaml
# Example company customizations
image:
  repository: "your-registry.company.com/awx-operator"
  tag: "2.19.1-company"

serviceAccount:
  name: "company-awx-operator"
  annotations:
    company.com/owner: "platform-team"

resources:
  limits:
    cpu: "1000m"
    memory: "1Gi"

nodeSelector:
  company.com/node-type: "platform"
```

See [COMPANY-CUSTOMIZATION.md](COMPANY-CUSTOMIZATION.md) for complete customization options.

## Support

- **AWX Documentation**: https://ansible.readthedocs.io/projects/awx/
- **Operator Documentation**: https://ansible.readthedocs.io/projects/awx-operator/
- **Kubernetes Documentation**: https://kubernetes.io/docs/