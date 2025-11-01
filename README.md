# AWX Deployment Options on Azure

This repository contains multiple deployment methods for AWX (Ansible Web UI) on Azure infrastructure.

## Deployment Methods

### 1. AKS with AWX Operator (`aks-operator/`)
- **Method**: Kubernetes Operator
- **Infrastructure**: Azure Kubernetes Service (AKS)
- **Deployment**: `kubectl apply -f aks-operator/`
- **Best for**: Production environments, scalability

### 2. AKS with Helm (`aks-helm/`)
- **Method**: Helm Charts
- **Infrastructure**: Azure Kubernetes Service (AKS)
- **Deployment**: `./aks-helm/install.sh`
- **Best for**: Simplified Kubernetes deployments

### 3. Azure VM with Docker Compose (`azure-vm/`)
- **Method**: Docker Compose
- **Infrastructure**: Azure Virtual Machine
- **Deployment**: `docker-compose up -d`
- **Best for**: Development, testing, single-node setups

### 4. Terraform + AKS (`terraform-aks/`)
- **Method**: Infrastructure as Code
- **Infrastructure**: Azure Kubernetes Service (AKS)
- **Deployment**: `terraform apply`
- **Best for**: Automated infrastructure provisioning

### 5. Bicep + AKS (`bicep-deployment/`)
- **Method**: Azure Resource Manager templates
- **Infrastructure**: Azure Kubernetes Service (AKS)
- **Deployment**: `az deployment group create`
- **Best for**: Azure-native IaC approach

### 6. Azure Container Instances (`azure-container-instances/`)
- **Method**: Serverless containers
- **Infrastructure**: Azure Container Instances (ACI)
- **Deployment**: `az container create`
- **Best for**: Quick testing, serverless approach

## Quick Start Commands

```bash
# AKS Operator
kubectl apply -f aks-operator/

# Helm
helm repo add awx-operator https://ansible.github.io/awx-operator/
helm install awx awx-operator/awx-operator

# Terraform
cd terraform-aks && terraform init && terraform apply

# Bicep
az deployment group create --resource-group myRG --template-file bicep-deployment/main.bicep

# Azure Container Instances
az container create --resource-group myRG --file azure-container-instances/awx-aci.yaml
```

## Prerequisites
- Azure CLI
- kubectl (for Kubernetes deployments)
- Terraform (for Terraform deployment)
- Docker (for VM deployment)
- Helm (for Helm deployment)