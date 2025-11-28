# AWX on AKS Deployment Steps

Step-by-step execution guide for deploying AWX on Azure Kubernetes Service (AKS).

## Prerequisites

1. **Azure CLI** installed and configured
2. **kubectl** installed
3. **Helm** >= 3.0 installed
4. **Azure subscription** with appropriate permissions
5. **Existing AKS cluster** or ability to create one

## Step-by-Step Execution

### Step 1: Setup AKS Cluster (If not exists)

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "your-subscription-id"

# Create resource group
az group create --name awx-rg --location eastus

# Create AKS cluster
az aks create \
  --resource-group awx-rg \
  --name awx-aks \
  --node-count 3 \
  --node-vm-size Standard_D2s_v3 \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get AKS credentials
az aks get-credentials --resource-group awx-rg --name awx-aks
```

### Step 2: Verify Cluster Connection

```bash
# Verify cluster access
kubectl cluster-info

# Check nodes
kubectl get nodes

# Check available storage classes
kubectl get storageclass
```

### Step 3: Navigate to Project Directory

```bash
# Clone repository (if not done)
git clone <repository-url>
cd awx

# Navigate to Helm directory
cd aks-helm
```

### Step 4: Download Helm Chart

```bash
# Execute download script
./download-chart.sh

# Verify chart downloaded
ls -la awx-operator-chart/
```

**Expected Output:**
```
Chart downloaded to awx-operator-chart/
```

### Step 5: Customize Configuration (Optional)

```bash
# Edit values.yaml for company-specific settings
nano values.yaml

# Or copy and modify local values for AKS
cp values-local.yaml values-aks.yaml
# Edit values-aks.yaml as needed
```

**Key AKS Configurations:**
```yaml
# In values.yaml or values-aks.yaml
AWX:
  enabled: true
  name: awx-aks
  spec:
    service_type: LoadBalancer  # For external access
    
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 200m
    memory: 256Mi
```

### Step 6: Install AWX Operator

```bash
# Create namespace
kubectl create namespace awx

# Install using Helm
helm install awx-operator ./awx-operator-chart \
  -n awx \
  -f values.yaml

# Or with custom AKS values
# helm install awx-operator ./awx-operator-chart -n awx -f values-aks.yaml
```

**Expected Output:**
```
NAME: awx-operator
LAST DEPLOYED: [timestamp]
NAMESPACE: awx
STATUS: deployed
```

### Step 7: Wait for Operator Deployment

```bash
# Wait for operator to be ready
kubectl wait --for=condition=available --timeout=300s deployment/awx-operator-controller-manager -n awx

# Check operator status
kubectl get pods -n awx -l control-plane=controller-manager
```

**Expected Output:**
```
NAME                                               READY   STATUS    RESTARTS   AGE
awx-operator-controller-manager-xxxxxxxxxx-xxxxx   2/2     Running   0          2m
```

### Step 8: Wait for AWX Instance

```bash
# Check AWX custom resource
kubectl get awx -n awx

# Wait for AWX to be running (this may take 5-10 minutes)
kubectl wait --for=condition=Running --timeout=600s awx/awx -n awx

# Monitor AWX deployment progress
kubectl get pods -n awx -w
```

**Expected Final State:**
```
NAME                        READY   STATUS    RESTARTS   AGE
awx-postgres-xxxxx          1/1     Running   0          5m
awx-xxxxxx                  4/4     Running   0          3m
awx-operator-controller-manager-xxx  2/2     Running   0          8m
```

### Step 9: Verify Deployment

```bash
# Check all resources
kubectl get all -n awx

# Check AWX status
kubectl describe awx awx -n awx

# Check services
kubectl get svc -n awx
```

### Step 10: Get Access Information

```bash
# Get LoadBalancer external IP (for AKS)
kubectl get svc -n awx -o wide

# Get admin password
kubectl get secret awx-admin-password -n awx -o jsonpath="{.data.password}" | base64 --decode

# Get admin username (usually 'admin')
kubectl get secret awx-admin-password -n awx -o jsonpath="{.data.username}" | base64 --decode
```

### Step 11: Access AWX

#### Method 1: LoadBalancer (Production)
```bash
# Get external IP
EXTERNAL_IP=$(kubectl get svc awx-service -n awx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "AWX URL: http://$EXTERNAL_IP"
```

#### Method 2: Port Forward (Testing)
```bash
# Port forward for testing
kubectl port-forward svc/awx-service -n awx 8080:80

# Access via browser: http://localhost:8080
```

## Execution Summary

**Complete deployment command sequence:**

```bash
# 1. Setup (one-time)
az aks get-credentials --resource-group awx-rg --name awx-aks
cd awx/aks-helm

# 2. Deploy AWX
./download-chart.sh
kubectl create namespace awx
helm install awx-operator ./awx-operator-chart -n awx -f values.yaml

# 3. Wait and verify
kubectl wait --for=condition=available --timeout=300s deployment/awx-operator-controller-manager -n awx
kubectl wait --for=condition=Running --timeout=600s awx/awx -n awx

# 4. Get access info
kubectl get svc -n awx
kubectl get secret awx-admin-password -n awx -o jsonpath="{.data.password}" | base64 --decode
```

## Troubleshooting Commands

```bash
# Check operator logs
kubectl logs -n awx deployment/awx-operator-controller-manager

# Check AWX instance logs
kubectl logs -n awx -l app.kubernetes.io/name=awx

# Check events
kubectl get events -n awx --sort-by='.lastTimestamp'

# Describe AWX resource
kubectl describe awx awx -n awx

# Check persistent volumes
kubectl get pv,pvc -n awx
```

## Cleanup (If needed)

```bash
# Remove AWX instance
kubectl delete awx awx -n awx

# Remove Helm release
helm uninstall awx-operator -n awx

# Remove namespace
kubectl delete namespace awx

# Remove AKS cluster (if desired)
az aks delete --resource-group awx-rg --name awx-aks --yes --no-wait
```

## Expected Timeline

- **Step 1-5**: 5-10 minutes (setup and configuration)
- **Step 6-7**: 2-3 minutes (operator deployment)
- **Step 8**: 5-10 minutes (AWX instance deployment)
- **Step 9-11**: 2-3 minutes (verification and access)

**Total deployment time**: 15-25 minutes