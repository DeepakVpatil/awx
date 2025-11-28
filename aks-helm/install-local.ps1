# PowerShell version of local AWX installation

Write-Host "Starting local AWX deployment..." -ForegroundColor Green

# Create Helm chart if not exists
if (-not (Test-Path "awx-operator-chart")) {
    Write-Host "Downloading Helm chart..." -ForegroundColor Yellow
    .\download-chart.sh
}

# Create namespace
Write-Host "Creating namespace..." -ForegroundColor Yellow
kubectl create namespace awx --dry-run=client -o yaml | kubectl apply -f -

# Install AWX using local configuration
Write-Host "Installing AWX operator with local configuration..." -ForegroundColor Yellow
helm install awx-operator ./awx-operator-chart `
  -n awx `
  -f values-local.yaml

# Wait for operator to be ready
Write-Host "Waiting for operator to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=300s deployment/awx-operator-controller-manager -n awx

# Wait for AWX instance to be ready
Write-Host "Waiting for AWX instance to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=Running --timeout=600s awx/awx-local -n awx

Write-Host ""
Write-Host "AWX local deployment completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Access methods:" -ForegroundColor Cyan
Write-Host "1. Port forward: kubectl port-forward svc/awx-local-service -n awx 8080:80" -ForegroundColor White
Write-Host "2. NodePort: kubectl get svc -n awx (check NodePort)" -ForegroundColor White
Write-Host ""
Write-Host "Get admin password:" -ForegroundColor Cyan
Write-Host "kubectl get secret awx-local-admin-password -n awx -o jsonpath='{.data.password}' | %{[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_))}" -ForegroundColor White
Write-Host ""
Write-Host "Check status:" -ForegroundColor Cyan
Write-Host "kubectl get awx -n awx" -ForegroundColor White
Write-Host "kubectl get pods -n awx" -ForegroundColor White