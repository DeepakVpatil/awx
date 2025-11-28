# Local Deployment Troubleshooting

## Minikube Port Binding Issues (Windows)

### Problem
```
Failed to start cluster! StartHost failed: driver start: listen tcp4 127.0.0.1:49750: bind: 
An attempt was made to access a socket in a way forbidden by its access permissions.
```

### Solutions

#### Solution 1: Run as Administrator
```bash
# Open PowerShell/CMD as Administrator
# Then run minikube commands
minikube delete
minikube start --cpus=4 --memory=8192 --disk-size=20g
```

#### Solution 2: Use Different Driver
```bash
# Delete existing cluster
minikube delete

# Use Docker driver instead of VirtualBox
minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=20g

# Or use Hyper-V (Windows Pro/Enterprise)
minikube start --driver=hyperv --cpus=4 --memory=8192 --disk-size=20g
```

#### Solution 3: Change Port Range
```bash
# Delete existing cluster
minikube delete

# Start with different port range
minikube start --cpus=4 --memory=8192 --disk-size=20g --ports=22,80,443,2376,8443,10250,10251,10252,10255
```

#### Solution 4: Disable Windows Features (If using Hyper-V)
```bash
# Run in PowerShell as Administrator
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
# Restart computer
# Re-enable if needed:
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
```

## Alternative Local Solutions

### Option 1: Docker Desktop (Recommended for Windows)
```bash
# Install Docker Desktop
# Enable Kubernetes in Docker Desktop settings
# No additional setup needed

# Verify
kubectl cluster-info
kubectl get nodes
```

### Option 2: Kind (Kubernetes in Docker)
```bash
# Install kind
choco install kind

# Create cluster
kind create cluster --name awx-local

# Verify
kubectl cluster-info --context kind-awx-local
```

### Option 3: Rancher Desktop
```bash
# Install Rancher Desktop (alternative to Docker Desktop)
# Enable Kubernetes
# Use kubectl normally
```

## Windows-Specific Port Issues

### Check Port Usage
```bash
# Check what's using the port
netstat -ano | findstr :49750
netstat -ano | findstr :2376

# Kill process if needed (replace PID)
taskkill /PID <process_id> /F
```

### Reserved Port Ranges
```bash
# Check Windows reserved ports
netsh int ipv4 show excludedportrange protocol=tcp

# If port is reserved, use different driver or restart Windows
```

## Quick Local Deployment (No Minikube)

### Using Docker Desktop
```bash
# 1. Install Docker Desktop
# 2. Enable Kubernetes in Settings
# 3. Deploy AWX directly

cd aks-helm
./install-local.sh

# Access
kubectl port-forward svc/awx-local-service -n awx 8080:80
```

### Using Kind
```bash
# 1. Install kind
choco install kind

# 2. Create cluster
kind create cluster --name awx

# 3. Deploy AWX
cd aks-helm
./install-local.sh

# 4. Access
kubectl port-forward svc/awx-local-service -n awx 8080:80
```

## Firewall and Antivirus Issues

### Windows Defender
```bash
# Add minikube to Windows Defender exclusions
# Settings > Update & Security > Windows Security > Virus & threat protection
# Add exclusion for: C:\Users\<username>\.minikube\
```

### Corporate Firewall
```bash
# If behind corporate firewall, use Docker Desktop
# Or configure proxy settings:
minikube start --docker-env HTTP_PROXY=http://proxy.company.com:8080 \
               --docker-env HTTPS_PROXY=http://proxy.company.com:8080
```

## Resource Issues

### Insufficient Memory
```bash
# Check available memory
wmic computersystem get TotalPhysicalMemory

# Reduce memory allocation
minikube start --cpus=2 --memory=4096 --disk-size=10g
```

### Disk Space
```bash
# Check disk space
dir C:\ 

# Clean up Docker/minikube
minikube delete
docker system prune -a
```

## Recommended Local Setup for Windows

### Best Option: Docker Desktop
1. Install Docker Desktop
2. Enable Kubernetes
3. Allocate 8GB RAM, 4 CPUs
4. Deploy AWX directly

### Alternative: Kind
1. Install Docker Desktop (without Kubernetes)
2. Install Kind
3. Create Kind cluster
4. Deploy AWX

### Last Resort: WSL2 + Docker
1. Enable WSL2
2. Install Docker in WSL2
3. Use kubectl from WSL2
4. Deploy AWX in WSL2 environment

## WSL Issues

### WSL Service Disabled Error
```
The service cannot be started, either because it is disabled or because it has no enabled devices associated with it.
```

#### Enable WSL (Windows 10/11)
```bash
# Run PowerShell as Administrator

# Enable WSL feature
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Enable Virtual Machine Platform
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart computer
shutdown /r /t 0

# After restart, set WSL2 as default
wsl --set-default-version 2
```

#### Alternative: Skip WSL Entirely
```bash
# Use Docker Desktop (Windows native)
# No WSL required for Kubernetes

# Or use Kind with Docker Desktop
kind create cluster --name awx
```

## Verification Commands

```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces

# Check resources
kubectl top nodes
kubectl describe node

# Test deployment
kubectl create deployment test --image=nginx
kubectl get pods
kubectl delete deployment test
```