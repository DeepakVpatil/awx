#!/bin/bash

set -e

echo "🚀 Setting up Airflow for AWX Deployment..."

# Create required directories
echo "📁 Creating directories..."
mkdir -p dags/awx/environments/{dev,nonprod,prod}
mkdir -p dags/awx/aks-operator
mkdir -p logs plugins

# Set Airflow UID
export AIRFLOW_UID=$(id -u)
echo "AIRFLOW_UID=$AIRFLOW_UID" > .env

# Initialize Airflow database
echo "🗄️ Initializing Airflow..."
docker-compose up airflow-init

# Start services
echo "🔄 Starting Airflow services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services..."
sleep 30

# Check service status
echo "✅ Checking service status..."
docker-compose ps

echo "🎉 Setup complete!"
echo "📊 Airflow UI: http://localhost:8080"
echo "👤 Username: airflow"
echo "🔑 Password: airflow"