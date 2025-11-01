from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.models import Variable
import os

default_args = {
    'owner': 'awx-team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

def get_environment_config(environment):
    """Get environment-specific configuration"""
    configs = {
        'dev': {
            'namespace': 'awx-dev',
            'replicas': 1,
            'resources': 'small',
            'approval_required': False
        },
        'nonprod': {
            'namespace': 'awx-nonprod', 
            'replicas': 2,
            'resources': 'medium',
            'approval_required': True
        },
        'prod': {
            'namespace': 'awx-prod',
            'replicas': 3,
            'resources': 'large',
            'approval_required': True
        }
    }
    return configs.get(environment, configs['dev'])

def create_awx_deployment_dag(environment):
    """Create AWX deployment DAG for specific environment"""
    
    config = get_environment_config(environment)
    
    dag = DAG(
        f'awx_deployment_{environment}',
        default_args=default_args,
        description=f'Deploy AWX to {environment} environment',
        schedule_interval='@daily' if environment == 'dev' else None,
        catchup=False,
        tags=['awx', environment, 'deployment'],
    )

    # Pre-deployment validation
    validate_cluster = BashOperator(
        task_id='validate_cluster',
        bash_command=f'''
        kubectl cluster-info
        kubectl get nodes
        kubectl get ns {config["namespace"]} || kubectl create ns {config["namespace"]}
        ''',
        dag=dag,
    )

    # Terraform plan
    terraform_plan = BashOperator(
        task_id='terraform_plan',
        bash_command=f'''
        cd /opt/airflow/dags/awx/environments/{environment}
        terraform init
        terraform plan -out=tfplan
        ''',
        dag=dag,
    )

    # Terraform apply (conditional on approval for nonprod/prod)
    terraform_apply = BashOperator(
        task_id='terraform_apply',
        bash_command=f'''
        cd /opt/airflow/dags/awx/environments/{environment}
        terraform apply -auto-approve tfplan
        ''',
        dag=dag,
    )

    # Deploy AWX operator
    deploy_operator = BashOperator(
        task_id='deploy_awx_operator',
        bash_command=f'''
        kubectl apply -f /opt/airflow/dags/awx/aks-operator/awx-operator.yaml -n {config["namespace"]}
        kubectl wait --for=condition=available --timeout=300s deployment/awx-operator -n {config["namespace"]}
        ''',
        dag=dag,
    )

    # Deploy AWX instance
    deploy_instance = BashOperator(
        task_id='deploy_awx_instance',
        bash_command=f'''
        envsubst < /opt/airflow/dags/awx/aks-operator/awx-instance.yaml | kubectl apply -f - -n {config["namespace"]}
        kubectl wait --for=condition=Running --timeout=600s pod -l app.kubernetes.io/name=awx -n {config["namespace"]}
        ''',
        env={
            'AWX_NAMESPACE': config["namespace"],
            'AWX_REPLICAS': str(config["replicas"])
        },
        dag=dag,
    )

    # Health check
    health_check = BashOperator(
        task_id='health_check',
        bash_command=f'''
        kubectl get pods -n {config["namespace"]}
        kubectl get svc -n {config["namespace"]}
        kubectl logs -l app.kubernetes.io/name=awx -n {config["namespace"]} --tail=50
        ''',
        dag=dag,
    )

    # Post-deployment notification
    def send_notification(**context):
        print(f"AWX deployment to {environment} completed successfully!")
        return f"AWX {environment} deployment completed"

    notify = PythonOperator(
        task_id='send_notification',
        python_callable=send_notification,
        dag=dag,
    )

    # Set task dependencies
    validate_cluster >> terraform_plan >> terraform_apply >> deploy_operator >> deploy_instance >> health_check >> notify

    return dag

# Create DAGs for each environment
dev_dag = create_awx_deployment_dag('dev')
nonprod_dag = create_awx_deployment_dag('nonprod') 
prod_dag = create_awx_deployment_dag('prod')

# Make DAGs available to Airflow
globals()['awx_deployment_dev'] = dev_dag
globals()['awx_deployment_nonprod'] = nonprod_dag
globals()['awx_deployment_prod'] = prod_dag