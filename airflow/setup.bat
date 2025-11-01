@echo off
setlocal enabledelayedexpansion

echo 🚀 Setting up Airflow for AWX Deployment...

REM Create required directories
echo 📁 Creating directories...
if not exist "dags\awx\environments\dev" mkdir dags\awx\environments\dev
if not exist "dags\awx\environments\nonprod" mkdir dags\awx\environments\nonprod
if not exist "dags\awx\environments\prod" mkdir dags\awx\environments\prod
if not exist "dags\awx\aks-operator" mkdir dags\awx\aks-operator
if not exist "logs" mkdir logs
if not exist "plugins" mkdir plugins

REM Set Airflow UID
echo AIRFLOW_UID=50000> .env

REM Initialize Airflow database
echo 🗄️ Initializing Airflow...
docker-compose up airflow-init

REM Start services
echo 🔄 Starting Airflow services...
docker-compose up -d

REM Wait for services to be ready
echo ⏳ Waiting for services...
timeout /t 30 /nobreak >nul

REM Check service status
echo ✅ Checking service status...
docker-compose ps

echo 🎉 Setup complete!
echo 📊 Airflow UI: http://localhost:8080
echo 👤 Username: airflow
echo 🔑 Password: airflow