# Company-Specific AWX Operator Customization Guide

This document outlines the key configuration changes required to customize the AWX Operator deployment for your company's specific requirements.

## File Locations

- **Main Configuration**: `awx/aks-helm/values.yaml`
- **Installation Script**: `awx/aks-helm/install.sh`
- **Chart Download**: `awx/aks-helm/download-chart.sh`
- **Helm Chart**: `awx/aks-helm/awx-operator-chart/`

## values.yaml Variables (`awx/aks-helm/values.yaml`)

### 1. Image Configuration

```yaml
image:
  repository: "your-company-registry/awx-operator"  # Private registry
  tag: "2.19.1-company"                            # Custom tag
  pullPolicy: Always                               # Company policy
```

**Purpose**: Configure private container registry and company-approved image versions.

### 2. Service Account & RBAC

```yaml
serviceAccount:
  name: "company-awx-operator"
  annotations:
    company.com/owner: "platform-team"
    company.com/cost-center: "infrastructure"
```

**Purpose**: Apply company naming conventions and required metadata annotations.

### 3. Resource Limits

```yaml
resources:
  limits:
    cpu: "1000m"        # Company standards
    memory: "1Gi"       # Company standards
  requests:
    cpu: "200m"
    memory: "256Mi"
```

**Purpose**: Enforce company resource allocation policies and standards.

### 4. Security Context

```yaml
podSecurityContext:
  runAsUser: 1001       # Company UID
  fsGroup: 1001         # Company GID
  
securityContext:
  runAsUser: 1001       # Company security policy
```

**Purpose**: Comply with company security policies for user/group IDs.

### 5. Node Selection

```yaml
nodeSelector:
  company.com/node-type: "platform"
  kubernetes.io/arch: "amd64"

tolerations:
- key: "company.com/dedicated"
  operator: "Equal"
  value: "platform"
  effect: "NoSchedule"
```

**Purpose**: Ensure pods are scheduled on appropriate company infrastructure nodes.

## install.sh Variables (`awx/aks-helm/install.sh`)

### 6. Namespace & Labels

```bash
# Company namespace
kubectl create namespace company-awx

# Company-specific AWX instance
kubectl apply -f - <<EOF
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: company-awx
  namespace: company-awx
  labels:
    company.com/environment: "production"
    company.com/team: "platform"
spec:
  service_type: LoadBalancer
  ingress_type: ingress
  hostname: awx.company.com
EOF
```

**Purpose**: Apply company naming conventions and labeling standards to AWX resources.

### 7. Environment Variables

Add to `awx/aks-helm/values.yaml`:

```yaml
env:
- name: COMPANY_DOMAIN
  value: "company.com"
- name: LOG_LEVEL
  value: "INFO"
```

**Purpose**: Configure company-specific environment variables for integration and logging.

## Implementation Steps

1. **Review Current Configuration**: Examine existing `awx/aks-helm/values.yaml` file
2. **Update Image Settings**: Configure private registry in `awx/aks-helm/values.yaml`
3. **Apply Security Policies**: Update UID/GID in `awx/aks-helm/values.yaml`
4. **Set Resource Limits**: Apply company resource policies in `awx/aks-helm/values.yaml`
5. **Configure Node Placement**: Set node selectors and tolerations in `awx/aks-helm/values.yaml`
6. **Update Deployment Script**: Modify namespace and labels in `awx/aks-helm/install.sh`
7. **Test Deployment**: Run `./awx/aks-helm/install.sh` in non-production environment

## Validation

After applying customizations, verify:

- Pods are scheduled on correct nodes
- Resource limits are enforced
- Security contexts are applied
- Company labels and annotations are present
- Private registry authentication works (if applicable)

These variables allow customization for company policies, security requirements, and infrastructure standards.