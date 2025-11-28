# LoadBalancer Configuration for AWX on AKS

Configure Azure LoadBalancer for external access to AWX on Azure Kubernetes Service (AKS).

## LoadBalancer Types

### Public LoadBalancer (Default)

```yaml
# In aks-helm/values.yaml
AWX:
  enabled: true
  name: awx
  spec:
    service_type: LoadBalancer
    service_annotations:
      service.beta.kubernetes.io/azure-load-balancer-resource-group: "awx-rg"
```

### Internal LoadBalancer (Private Network)

```yaml
# For internal company access only
AWX:
  enabled: true
  name: awx
  spec:
    service_type: LoadBalancer
    service_annotations:
      service.beta.kubernetes.io/azure-load-balancer-internal: "true"
      service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "awx-subnet"
      service.beta.kubernetes.io/azure-load-balancer-resource-group: "awx-rg"
```

## Static IP Configuration

### Reserve Static IP

```bash
# Create static public IP
az network public-ip create \
  --resource-group awx-rg \
  --name awx-public-ip \
  --sku Standard \
  --allocation-method Static

# Get the IP address
az network public-ip show \
  --resource-group awx-rg \
  --name awx-public-ip \
  --query ipAddress \
  --output tsv
```

### Use Static IP in AWX

```yaml
AWX:
  enabled: true
  name: awx
  spec:
    service_type: LoadBalancer
    service_annotations:
      service.beta.kubernetes.io/azure-load-balancer-resource-group: "awx-rg"
      service.beta.kubernetes.io/azure-pip-name: "awx-public-ip"
```

## SSL/TLS Configuration

### Azure Application Gateway (Recommended)

```yaml
# Use Application Gateway for SSL termination
AWX:
  spec:
    service_type: ClusterIP  # Internal service
    ingress_type: ingress
    hostname: awx.company.com
    
    # Ingress configuration
    ingress_annotations:
      kubernetes.io/ingress.class: azure/application-gateway
      appgw.ingress.kubernetes.io/ssl-redirect: "true"
      appgw.ingress.kubernetes.io/backend-protocol: "http"
```

### NGINX Ingress with LoadBalancer

```yaml
# Install NGINX Ingress Controller first
# helm install ingress-nginx ingress-nginx/ingress-nginx

AWX:
  spec:
    service_type: ClusterIP
    ingress_type: ingress
    hostname: awx.company.com
    
    ingress_annotations:
      kubernetes.io/ingress.class: nginx
      cert-manager.io/cluster-issuer: letsencrypt-prod
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
    
    ingress_tls_secret: awx-tls-secret
```

## Network Security

### Network Security Groups (NSG)

```bash
# Create NSG rule for AWX access
az network nsg rule create \
  --resource-group awx-rg \
  --nsg-name awx-nsg \
  --name AllowAWXHTTPS \
  --protocol Tcp \
  --priority 1000 \
  --destination-port-range 443 \
  --source-address-prefixes "10.0.0.0/8" \
  --access Allow
```

### Firewall Rules

```yaml
# Restrict access to specific IP ranges
AWX:
  spec:
    service_annotations:
      service.beta.kubernetes.io/azure-load-balancer-resource-group: "awx-rg"
      service.beta.kubernetes.io/load-balancer-source-ranges: "10.0.0.0/8,192.168.0.0/16"
```

## DNS Configuration

### Azure DNS Zone

```bash
# Create DNS zone
az network dns zone create \
  --resource-group awx-rg \
  --name company.com

# Create A record for AWX
az network dns record-set a add-record \
  --resource-group awx-rg \
  --zone-name company.com \
  --record-set-name awx \
  --ipv4-address <LOADBALANCER_IP>
```

### Custom Domain in AWX

```yaml
AWX:
  spec:
    hostname: awx.company.com
    service_type: LoadBalancer
```

## Health Checks and Monitoring

### LoadBalancer Health Probes

```yaml
AWX:
  spec:
    service_type: LoadBalancer
    # Health check configuration
    web_resource_requirements:
      requests:
        cpu: 200m
        memory: 256Mi
      limits:
        cpu: 1000m
        memory: 1Gi
    
    # Readiness and liveness probes
    web_extra_settings:
      - setting: ALLOWED_HOSTS
        value: "['awx.company.com', 'localhost']"
```

## Complete AKS LoadBalancer Configuration

### Production Configuration

```yaml
# Complete values.yaml for AKS with LoadBalancer
AWX:
  enabled: true
  name: awx-prod
  spec:
    service_type: LoadBalancer
    hostname: awx.company.com
    
    # LoadBalancer configuration
    service_annotations:
      service.beta.kubernetes.io/azure-load-balancer-resource-group: "awx-rg"
      service.beta.kubernetes.io/azure-pip-name: "awx-public-ip"
      service.beta.kubernetes.io/load-balancer-source-ranges: "10.0.0.0/8"
    
    # Resource allocation
    web_resource_requirements:
      requests:
        cpu: 500m
        memory: 1Gi
      limits:
        cpu: 2000m
        memory: 4Gi
    
    task_resource_requirements:
      requests:
        cpu: 500m
        memory: 1Gi
      limits:
        cpu: 2000m
        memory: 4Gi
    
    # High availability
    web_replicas: 2
    task_replicas: 2
    
    # PostgreSQL configuration
    postgres_storage_requirements:
      requests:
        storage: 50Gi
      
  postgres:
    enabled: true
```

## Deployment Commands

### Deploy with LoadBalancer

```bash
# Navigate to Helm directory
cd aks-helm

# Download chart
./download-chart.sh

# Deploy with LoadBalancer configuration
helm install awx-operator ./awx-operator-chart \
  -n awx \
  --create-namespace \
  -f values.yaml

# Wait for LoadBalancer IP assignment
kubectl get svc -n awx -w
```

### Get LoadBalancer Information

```bash
# Get external IP
kubectl get svc -n awx -o wide

# Get LoadBalancer details
kubectl describe svc awx-service -n awx

# Check LoadBalancer events
kubectl get events -n awx --field-selector involvedObject.kind=Service
```

## Troubleshooting LoadBalancer

### Common Issues

```bash
# Check service status
kubectl get svc -n awx
kubectl describe svc awx-service -n awx

# Check LoadBalancer provisioning
kubectl get events -n awx | grep LoadBalancer

# Verify AKS cluster LoadBalancer support
az aks show --resource-group awx-rg --name awx-aks --query networkProfile

# Check Azure LoadBalancer in portal
az network lb list --resource-group MC_awx-rg_awx-aks_eastus
```

### LoadBalancer Stuck in Pending

```bash
# Check cluster permissions
az role assignment list --assignee $(az aks show -g awx-rg -n awx-aks --query identity.principalId -o tsv)

# Verify network configuration
kubectl describe nodes

# Check Azure resource quotas
az vm list-usage --location eastus
```

## Security Best Practices

1. **Use internal LoadBalancer** for company-only access
2. **Implement NSG rules** to restrict access
3. **Use static IP addresses** for consistent access
4. **Configure SSL/TLS** with Application Gateway or Ingress
5. **Monitor LoadBalancer metrics** in Azure Monitor
6. **Regular security reviews** of access patterns

## Cost Optimization

```yaml
# Use Standard SKU for production
service_annotations:
  service.beta.kubernetes.io/azure-load-balancer-sku: "Standard"

# For development, use Basic SKU
service_annotations:
  service.beta.kubernetes.io/azure-load-balancer-sku: "Basic"
```

This configuration provides enterprise-grade LoadBalancer setup for AWX on AKS with proper security and monitoring.