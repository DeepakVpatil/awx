@echo off
REM AWX Local Deployment Script for Docker Desktop Kubernetes (Windows)
REM Usage: deploy-local.bat

echo Starting AWX local deployment on Docker Desktop Kubernetes...

REM Check if kubectl is available
kubectl version --client >nul 2>&1
if %errorlevel% neq 0 (
    echo kubectl not found. Please install kubectl first.
    exit /b 1
)

REM Check if Docker Desktop Kubernetes is running
kubectl cluster-info >nul 2>&1
if %errorlevel% neq 0 (
    echo Kubernetes cluster not accessible. Please enable Kubernetes in Docker Desktop.
    exit /b 1
)

REM Check if Helm is available
helm version --short >nul 2>&1
if %errorlevel% neq 0 (
    echo Helm not found. Please install Helm first.
    exit /b 1
)

echo Prerequisites check passed

REM Create namespace
echo Creating AWX namespace...
kubectl create namespace awx --dry-run=client -o yaml | kubectl apply -f -

REM Add AWX operator Helm repository
echo Adding AWX operator Helm repository...
helm repo add awx-operator https://ansible.github.io/awx-operator/
helm repo update

REM Create local values file
echo Creating local configuration...
(
echo # Local Docker Desktop Configuration
echo replicaCount: 1
echo.
echo image:
echo   repository: quay.io/ansible/awx-operator
echo   pullPolicy: IfNotPresent
echo   tag: "2.19.1"
echo.
echo resources:
echo   limits:
echo     cpu: 200m
echo     memory: 256Mi
echo   requests:
echo     cpu: 100m
echo     memory: 128Mi
echo.
echo AWX:
echo   enabled: true
echo   name: awx-local
echo   spec:
echo     service_type: NodePort
echo     web_resource_requirements:
echo       requests:
echo         cpu: 100m
echo         memory: 256Mi
echo       limits:
echo         cpu: 500m
echo         memory: 1Gi
echo     task_resource_requirements:
echo       requests:
echo         cpu: 100m
echo         memory: 256Mi
echo       limits:
echo         cpu: 500m
echo         memory: 1Gi
) > values-local.yaml

REM Install AWX operator
echo Installing AWX operator...
helm install awx-operator awx-operator/awx-operator -n awx -f values-local.yaml

REM Wait for operator
echo Waiting for AWX operator to be ready...
kubectl wait --for=condition=available --timeout=300s deployment/awx-operator-controller-manager -n awx

REM Create AWX instance
echo Creating AWX instance...
(
echo apiVersion: awx.ansible.com/v1beta1
echo kind: AWX
echo metadata:
echo   name: awx-local
echo   namespace: awx
echo spec:
echo   service_type: NodePort
echo   web_replicas: 1
echo   task_replicas: 1
echo   postgres_storage_requirements:
echo     requests:
echo       storage: 2Gi
echo   projects_persistence: true
echo   projects_storage_size: 1Gi
) > awx-instance-local.yaml

kubectl apply -f awx-instance-local.yaml

echo Waiting for AWX instance to be ready (this may take 5-10 minutes)...
kubectl wait --for=condition=Running --timeout=600s awx/awx-local -n awx

echo.
echo AWX local deployment completed successfully!
echo.
echo Access Information:
echo Username: admin
echo.
echo To get password:
echo kubectl get secret awx-local-admin-password -n awx -o jsonpath="{.data.password}" | base64 -d
echo.
echo Access Methods:
echo 1. Port Forward: kubectl port-forward svc/awx-local-service -n awx 8080:80
echo    Then open: http://localhost:8080
echo.
echo 2. Check NodePort: kubectl get svc awx-local-service -n awx
echo.
echo Useful Commands:
echo Check status: kubectl get awx -n awx
echo View pods: kubectl get pods -n awx
echo.
echo Cleanup: helm uninstall awx-operator -n awx && kubectl delete namespace awx

pause