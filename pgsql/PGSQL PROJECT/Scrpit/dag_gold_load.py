
from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from datetime import datetime

with DAG(
    dag_id="gold_layer_load",
    start_date=datetime(2024,1,1),
    schedule_interval="0 23 * * *",
    catchup=False
) as dag:

    run_gold_proc = PostgresOperator(
        task_id="run_gold_procedure",
        postgres_conn_id="postgres_local",
        sql="CALL gold.dwh_load_todays_data();"
    )
