
from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from datetime import datetime

with DAG(
    dag_id="bronze_prepare_tables",
    start_date=datetime(2024,1,1),
    schedule_interval="0 23 * * *",
    catchup=False
) as dag:

    run_bronze_proc = PostgresOperator(
        task_id="run_bronze_procedure",
        postgres_conn_id="postgres_local",
        sql="CALL bronze.dwh_load_crm_erp_bronze();"
    )
