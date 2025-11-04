# AWX Deployment Options on Azure

This repository contains multiple deployment methods for AWX (Ansible Web UI) on Azure infrastructure with support for multi-environment deployments and CI/CD automation.

## Deployment Methods

### 1. Environment-Specific Terraform (`environments/`)
- **Method**: Modular Infrastructure as Code
- **Infrastructure**: Azure Kubernetes Service (AKS)
- **Environments**: dev, nonprod, prod
- **Deployment**: `cd environments/{env} && terraform apply`
- **Best for**: Production-ready multi-environment deployments

### 2. Airflow Automation (`airflow/`)
- **Method**: Apache Airflow DAGs
- **Infrastructure**: Automated AWX deployment pipeline
- **Deployment**: Airflow web UI or API
- **Best for**: CI/CD automation, scheduled deployments

### 3. AKS with AWX Operator (`aks-operator/`)
- **Method**: Kubernetes Operator
- **Infrastructure**: Azure Kubernetes Service (AKS)
- **Deployment**: `kubectl apply -f aks-operator/`
- **Best for**: Direct Kubernetes deployments

### 4. AKS with Helm (`aks-helm/`)
- **Method**: Helm Charts
- **Infrastructure**: Azure Kubernetes Service (AKS)
- **Deployment**: `./aks-helm/install.sh`
- **Best for**: Simplified Kubernetes deployments

### 5. Azure VM with Docker Compose (`azure-vm/`)
- **Method**: Docker Compose
- **Infrastructure**: Azure Virtual Machine
- **Deployment**: `docker-compose up -d`
- **Best for**: Development, testing, single-node setups

### 6. Terraform + AKS (`terraform-aks/`)
- **Method**: Infrastructure as Code
- **Infrastructure**: Azure Kubernetes Service (AKS)
- **Deployment**: `terraform apply`
- **Best for**: Single environment deployments

### 7. Bicep + AKS (`bicep-deployment/`)
- **Method**: Azure Resource Manager templates
- **Infrastructure**: Azure Kubernetes Service (AKS)
- **Deployment**: `az deployment group create`
- **Best for**: Azure-native IaC approach

### 8. Azure Container Instances (`azure-container-instances/`)
- **Method**: Serverless containers
- **Infrastructure**: Azure Container Instances (ACI)
- **Deployment**: `az container create`
- **Best for**: Quick testing, serverless approach

## Environment Overview

| Environment | Node Count | VM Size | Purpose |
|-------------|------------|---------|----------|
| **dev** | 2 | Standard_B2s | Development and testing |
| **nonprod** | 3 | Standard_D2s_v3 | Pre-production validation |
| **prod** | 5 | Standard_D4s_v3 | Production workloads |

## Quick Start Commands

### Environment-Specific Deployment (Recommended)
```bash
# Development environment
cd environments/dev
terraform init && terraform apply

# Non-production environment
cd environments/nonprod
terraform init && terraform apply

# Production environment
cd environments/prod
terraform init && terraform apply
```

### Alternative Deployment Methods
```bash
# AKS Operator
kubectl apply -f aks-operator/

# Helm
helm repo add awx-operator https://ansible.github.io/awx-operator/
helm install awx awx-operator/awx-operator

# Terraform (single environment)
cd terraform-aks && terraform init && terraform apply

# Bicep
az deployment group create --resource-group myRG --template-file bicep-deployment/main.bicep

# Azure Container Instances
az container create --resource-group myRG --file azure-container-instances/awx-aci.yaml
```

## Prerequisites
- Azure CLI installed and configured
- Terraform >= 1.0
- kubectl
- Helm >= 3.0 (for Helm deployments)
- Docker (for VM deployment)
- Apache Airflow (for automated deployments)
- Azure subscription with appropriate permissions

## Repository Structure

```
├── airflow/                    # Airflow DAGs for automated deployment
│   ├── dags/                   # Deployment DAGs
│   └── environments/           # Environment-specific configs
├── environments/               # Multi-environment Terraform
│   ├── dev/                    # Development environment
│   ├── nonprod/                # Non-production environment
│   └── prod/                   # Production environment
├── modules/                    # Reusable Terraform modules
│   ├── aks-cluster/            # AKS cluster module
│   ├── awx-deployment/         # AWX deployment module
│   └── awx-infrastructure/     # Infrastructure module
├── aks-operator/               # Direct Kubernetes deployment
├── aks-helm/                   # Helm chart deployment
├── azure-vm/                   # Docker Compose on VM
├── terraform-aks/              # Single environment Terraform
├── bicep-deployment/           # Azure Bicep templates
└── azure-container-instances/  # ACI deployment
```

## Getting Started

1. **Authentication Setup**
```bash
az login
az account set --subscription "your-subscription-id"
```

2. **Choose Your Deployment Method**
   - For production: Use `environments/` with Terraform
   - For automation: Use `airflow/` DAGs
   - For quick testing: Use `aks-operator/` or `azure-vm/`

3. **Follow Environment-Specific Instructions**
   - See [INSTALLATION.md](INSTALLATION.md) for detailed setup

## Access AWX

```bash
# Get admin password
kubectl get secret awx-admin-password -n awx-{environment} -o jsonpath="{.data.password}" | base64 --decode

# Port forward to access UI
kubectl port-forward svc/awx-service -n awx-{environment} 8080:80

# Access via browser: http://localhost:8080
# Username: admin, Password: (from above command)
```