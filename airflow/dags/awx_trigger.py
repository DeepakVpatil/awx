from datetime import datetime
from airflow import DAG
from airflow.operators.bash import BashOperator

# Environment configs
ENVS = {
    'dev': 'awx-dev',
    'nonprod': 'awx-nonprod', 
    'prod': 'awx-prod'
}

def create_dag(env):
    return DAG(
        f'awx_{env}',
        start_date=datetime(2024, 1, 1),
        schedule_interval=None,
        catchup=False
    )

# Create deployment tasks for each environment
for env, namespace in ENVS.items():
    dag = create_dag(env)
    
    BashOperator(
        task_id='deploy',
        bash_command=f'kubectl apply -f /opt/airflow/dags/manifests/ -n {namespace}',
        dag=dag
    )
    
    globals()[f'awx_{env}'] = dag