from datetime import datetime
from airflow import DAG
from airflow.operators.bash import BashOperator

# Environment configurations
ENVIRONMENTS = {
    'dev': {'namespace': 'awx-dev', 'replicas': 1},
    'nonprod': {'namespace': 'awx-nonprod', 'replicas': 2},
    'prod': {'namespace': 'awx-prod', 'replicas': 3}
}

def create_awx_dag(env):
    config = ENVIRONMENTS[env]
    
    dag = DAG(
        f'awx_deploy_{env}',
        start_date=datetime(2024, 1, 1),
        schedule_interval=None,
        catchup=False,
        tags=['awx', env]
    )
    
    deploy = BashOperator(
        task_id='deploy_awx',
        bash_command=f'''
        kubectl get ns {config["namespace"]} || kubectl create ns {config["namespace"]}
        kubectl apply -f /opt/airflow/dags/aks-operator/awx-operator.yaml -n {config["namespace"]}
        AWX_NAMESPACE={config["namespace"]} AWX_REPLICAS={config["replicas"]} envsubst < /opt/airflow/dags/aks-operator/awx-instance.yaml | kubectl apply -f - -n {config["namespace"]}
        ''',
        dag=dag
    )
    
    return dag

# Create DAGs
for env in ENVIRONMENTS:
    globals()[f'awx_deploy_{env}'] = create_awx_dag(env)