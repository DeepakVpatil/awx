# AWX Environment Installation Guide

This guide covers the installation of AWX across different environments using Terraform infrastructure as code.

## Prerequisites

- Azure CLI installed and configured
- Terraform >= 1.0
- kubectl
- Helm >= 3.0
- Azure subscription with appropriate permissions

## Environment Overview

| Environment | Node Count | VM Size | Kubernetes Version | Purpose |
|-------------|------------|---------|-------------------|---------|
| **dev** | 2 | Standard_B2s | 1.28 | Development and testing |
| **nonprod** | 3 | Standard_D2s_v3 | 1.28 | Pre-production validation |
| **prod** | 5 | Standard_D4s_v3 | 1.28 | Production workloads |

## Installation Steps

### 1. Authentication Setup

```bash
# Login to Azure
az login

# Set subscription (if multiple subscriptions)
az account set --subscription "your-subscription-id"
```

### 2. Environment-Specific Deployment

#### Development Environment

```bash
cd environments/dev

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure
terraform apply
```

**Configuration:**
- Location: East US
- Nodes: 2 x Standard_B2s
- Namespace: awx-dev
- Cost-optimized for development

#### Non-Production Environment

```bash
cd environments/nonprod

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure
terraform apply
```

**Configuration:**
- Location: East US
- Nodes: 3 x Standard_D2s_v3
- Namespace: awx-nonprod
- Balanced performance for testing

#### Production Environment

```bash
cd environments/prod

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure
terraform apply
```

**Configuration:**
- Location: East US
- Nodes: 5 x Standard_D4s_v3
- Namespace: awx-prod
- High availability and performance

### 3. Post-Deployment Verification

```bash
# Get AKS credentials
az aks get-credentials --resource-group awx-{environment}-rg --name awx-{environment}-aks

# Verify cluster status
kubectl get nodes

# Check AWX pods
kubectl get pods -n awx-{environment}

# Get AWX service URL
kubectl get svc -n awx-{environment}
```

## Environment Variables

### Development
```hcl
location           = "East US"
node_count         = 2
vm_size           = "Standard_B2s"
kubernetes_version = "1.28"
awx_operator_version = "2.7.2"
```

### Non-Production
```hcl
location           = "East US"
node_count         = 3
vm_size           = "Standard_D2s_v3"
kubernetes_version = "1.28"
awx_operator_version = "2.7.2"
```

### Production
```hcl
location           = "East US"
node_count         = 5
vm_size           = "Standard_D4s_v3"
kubernetes_version = "1.28"
awx_operator_version = "2.7.2"
```

## Customization

To customize deployment parameters, modify the `terraform.tfvars` file in each environment directory:

```hcl
# Example customization
location           = "West US 2"
node_count         = 4
vm_size           = "Standard_D2s_v3"
kubernetes_version = "1.29"
awx_operator_version = "2.8.0"
```

## Access AWX

1. **Get admin password:**
```bash
kubectl get secret awx-admin-password -n awx-{environment} -o jsonpath="{.data.password}" | base64 --decode
```

2. **Port forward to access UI:**
```bash
kubectl port-forward svc/awx-service -n awx-{environment} 8080:80
```

3. **Access via browser:**
- URL: http://localhost:8080
- Username: admin
- Password: (from step 1)

## Cleanup

To destroy the infrastructure:

```bash
cd environments/{environment}
terraform destroy
```

## Troubleshooting

### Common Issues

1. **Authentication errors:**
```bash
az login --use-device-code
```

2. **Terraform state issues:**
```bash
terraform refresh
```

3. **Kubernetes connection issues:**
```bash
az aks get-credentials --resource-group awx-{environment}-rg --name awx-{environment}-aks --overwrite-existing
```

### Logs and Monitoring

```bash
# Check AWX operator logs
kubectl logs -n awx-{environment} -l app.kubernetes.io/name=awx-operator

# Check AWX instance logs
kubectl logs -n awx-{environment} -l app.kubernetes.io/name=awx
```

## Security Considerations

- All environments use Azure AD integration
- Network security groups restrict access
- TLS encryption enabled by default
- Regular security updates via AWX operator

## Support

For issues and questions:
1. Check Terraform logs: `terraform apply -auto-approve`
2. Verify Azure permissions
3. Review Kubernetes events: `kubectl get events -n awx-{environment}`