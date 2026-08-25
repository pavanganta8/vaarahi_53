import os
import time
import pandas as pd

def load_bronze(base_dir=None):
    """
    Simulates the bronze.load_bronze stored procedure.
    Reads source CSV files and copies them to the python/datasets/bronze/ directory.
    """
    if base_dir is None:
        # Determine paths relative to this script
        script_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.abspath(os.path.join(script_dir, "..", ".."))
    else:
        project_root = os.path.abspath(base_dir)

    datasets_dir = os.path.join(project_root, "pgsql", "datasets")
    bronze_dir = os.path.join(project_root, "python", "datasets", "bronze")
    os.makedirs(bronze_dir, exist_ok=True)

    print("================================================")
    print("Loading Bronze Layer")
    print("================================================")
    batch_start_time = time.time()

    # Source CRM files mapping (lowercase filenames)
    crm_files = {
        "crm_cust_info": "source_crm/cust_info.csv",
        "crm_prd_info": "source_crm/prd_info.csv",
        "crm_sales_details": "source_crm/sales_details.csv"
    }

    # Source ERP files mapping (uppercase filenames as found on filesystem)
    erp_files = {
        "erp_loc_a101": "source_erp/LOC_A101.csv",
        "erp_cust_az12": "source_erp/CUST_AZ12.csv",
        "erp_px_cat_g1v2": "source_erp/PX_CAT_G1V2.csv"
    }

    print("------------------------------------------------")
    print("Loading CRM Tables")
    print("------------------------------------------------")
    for table_name, rel_path in crm_files.items():
        start_time = time.time()
        source_path = os.path.join(datasets_dir, rel_path)
        dest_path = os.path.join(bronze_dir, f"{table_name}.csv")

        print(f">> Truncating & Loading: {table_name}")
        if os.path.exists(source_path):
            df = pd.read_csv(source_path)
            df.to_csv(dest_path, index=False)
            duration = time.time() - start_time
            print(f">> Load Duration: {duration:.2f} seconds")
            print(f">> Rows Loaded: {len(df)}")
        else:
            print(f"WARNING: Source file not found: {source_path}")
        print(">> -------------")

    print("------------------------------------------------")
    print("Loading ERP Tables")
    print("------------------------------------------------")
    for table_name, rel_path in erp_files.items():
        start_time = time.time()
        source_path = os.path.join(datasets_dir, rel_path)
        dest_path = os.path.join(bronze_dir, f"{table_name}.csv")

        print(f">> Truncating & Loading: {table_name}")
        if os.path.exists(source_path):
            df = pd.read_csv(source_path)
            df.to_csv(dest_path, index=False)
            duration = time.time() - start_time
            print(f">> Load Duration: {duration:.2f} seconds")
            print(f">> Rows Loaded: {len(df)}")
        else:
            print(f"WARNING: Source file not found: {source_path}")
        print(">> -------------")

    batch_duration = time.time() - batch_start_time
    print("==========================================")
    print("Loading Bronze Layer is Completed")
    print(f"   - Total Load Duration: {batch_duration:.2f} seconds")
    print("==========================================")

if __name__ == "__main__":
    load_bronze()
