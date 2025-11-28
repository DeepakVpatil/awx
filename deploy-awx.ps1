# PowerShell version of AWX deployment script

Write-Host "Starting AWX deployment..." -ForegroundColor Green

# Add AWX Operator Helm repository
Write-Host "Adding Helm repository..." -ForegroundColor Yellow
helm repo add awx-operator https://ansible-community.github.io/awx-operator-helm/
helm repo update

# Deploy AWX Operator
Write-Host "Installing AWX Operator..." -ForegroundColor Yellow
helm install awx-operator awx-operator/awx-operator `
  --namespace awx `
  --create-namespace `
  --version 2.19.1

# Wait for operator to be ready
Write-Host "Waiting for operator to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=300s deployment/awx-operator-controller-manager -n awx

# Create AWX instance using here-string
Write-Host "Creating AWX instance..." -ForegroundColor Yellow
$awxManifest = @"
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  service_type: ClusterIP
"@

$awxManifest | kubectl apply -f -

Write-Host "AWX deployment complete!" -ForegroundColor Green
Write-Host "Check status with: kubectl get awx -n awx" -ForegroundColor Cyan