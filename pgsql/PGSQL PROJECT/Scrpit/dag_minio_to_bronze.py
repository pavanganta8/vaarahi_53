
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
from minio import Minio
import psycopg2
import tempfile
import os

def load_minio_files():

    client = Minio(
        "host.docker.internal:9000",
        access_key="admin",
        secret_key="admin123",
        secure=False
    )

    conn = psycopg2.connect(
        host="host.docker.internal",
        database="data_ware_house",
        user="postgres",
        password="postgres",
        port="5432"
    )

    cur = conn.cursor()

    files = {
        "crm": {
            "cust_info.csv": "bronze.crm_cust_info",
            "prd_info.csv": "bronze.crm_prd_info",
            "sales_details.csv": "bronze.crm_sales_details"
        },
        "erp": {
            "loc_a101.csv": "bronze.erp_loc_a101",
            "px_cat_g1v2.csv": "bronze.erp_px_cat_g1v2",
            "cust_az12.csv": "bronze.erp_cust_az12"
        }
    }

    for bucket, tables in files.items():
        for file, table in tables.items():

            tmp = tempfile.NamedTemporaryFile(delete=False)
            client.fget_object(bucket, file, tmp.name)

            with open(tmp.name, "r") as f:
                cur.copy_expert(f"COPY {table} FROM STDIN WITH CSV HEADER", f)

            os.unlink(tmp.name)

    conn.commit()
    cur.close()
    conn.close()

with DAG(
    dag_id="minio_to_bronze",
    start_date=datetime(2024,1,1),
    schedule_interval="0 23 * * *",
    catchup=False
) as dag:

    load_task = PythonOperator(
        task_id="load_bucket_data",
        python_callable=load_minio_files
    )
