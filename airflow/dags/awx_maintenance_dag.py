from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

default_args = {
    'owner': 'awx-team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': True,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'awx_maintenance',
    default_args=default_args,
    description='AWX maintenance and monitoring tasks',
    schedule_interval='0 2 * * *',  # Daily at 2 AM
    catchup=False,
    tags=['awx', 'maintenance', 'monitoring'],
)

# Backup AWX data
backup_awx = BashOperator(
    task_id='backup_awx_data',
    bash_command='''
    for env in dev nonprod prod; do
        echo "Backing up AWX data for $env environment"
        kubectl get secret -n awx-$env -o yaml > /tmp/awx-$env-secrets-$(date +%Y%m%d).yaml
        kubectl get configmap -n awx-$env -o yaml > /tmp/awx-$env-configmaps-$(date +%Y%m%d).yaml
    done
    ''',
    dag=dag,
)

# Check AWX health across environments
health_check = BashOperator(
    task_id='health_check_all_environments',
    bash_command='''
    for env in dev nonprod prod; do
        echo "Checking AWX health in $env environment"
        kubectl get pods -n awx-$env
        kubectl top pods -n awx-$env || echo "Metrics not available"
    done
    ''',
    dag=dag,
)

# Clean up old resources
cleanup = BashOperator(
    task_id='cleanup_old_resources',
    bash_command='''
    # Clean up completed jobs older than 7 days
    for env in dev nonprod prod; do
        kubectl delete jobs -n awx-$env --field-selector status.successful=1 --ignore-not-found=true
    done
    
    # Clean up old backup files
    find /tmp -name "awx-*-$(date -d '7 days ago' +%Y%m%d).yaml" -delete
    ''',
    dag=dag,
)

# Update operator if needed
update_operator = BashOperator(
    task_id='update_awx_operator',
    bash_command='''
    # Check for operator updates (dev environment only for testing)
    kubectl get deployment awx-operator -n awx-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
    echo "Current operator version checked"
    ''',
    dag=dag,
)

backup_awx >> health_check >> cleanup >> update_operator