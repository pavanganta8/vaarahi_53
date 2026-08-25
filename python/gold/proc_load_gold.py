import os
import time
import pandas as pd
import numpy as np

def load_gold(base_dir=None, filter_current_month=True):
    """
    Simulates the gold.load_gold stored procedure.
    Reads data from python/datasets/silver/, joins and builds dimensional models,
    and writes them to python/datasets/gold/.
    """
    if base_dir is None:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.abspath(os.path.join(script_dir, "..", ".."))
    else:
        project_root = os.path.abspath(base_dir)

    silver_dir = os.path.join(project_root, "python", "datasets", "silver")
    gold_dir = os.path.join(project_root, "python", "datasets", "gold")
    os.makedirs(gold_dir, exist_ok=True)

    print("================================================")
    print("Loading Gold Layer")
    print("================================================")
    batch_start_time = time.time()

    # Load required silver datasets
    print(">> Reading Silver Layer datasets...")
    try:
        df_ci = pd.read_csv(os.path.join(silver_dir, "crm_cust_info.csv"))
        df_ca = pd.read_csv(os.path.join(silver_dir, "erp_cust_az12.csv"))
        df_la = pd.read_csv(os.path.join(silver_dir, "erp_loc_a101.csv"))
        df_pn = pd.read_csv(os.path.join(silver_dir, "crm_prd_info.csv"))
        df_pc = pd.read_csv(os.path.join(silver_dir, "erp_px_cat_g1v2.csv"))
        df_sd = pd.read_csv(os.path.join(silver_dir, "crm_sales_details.csv"))
    except FileNotFoundError as e:
        print(f"ERROR: A required silver table is missing. Run load_silver first. Details: {e}")
        return

    # 1. Loading gold.dim_customers
    start_time = time.time()
    print(">> Truncating & Inserting: gold.dim_customers")
    
    # Align join keys (convert to strings and strip whitespaces)
    df_ci['cst_key'] = df_ci['cst_key'].astype(str).str.strip()
    df_ca['cid'] = df_ca['cid'].astype(str).str.strip()
    df_la['cid'] = df_la['cid'].astype(str).str.strip()
    
    # Merge datasets
    df_cust = df_ci.merge(df_ca, left_on='cst_key', right_on='cid', how='left')
    df_cust = df_cust.merge(df_la, left_on='cst_key', right_on='cid', how='left')
    
    # Gender Logic: CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr ELSE COALESCE(ca.gen, 'n/a') END
    gender_cond = df_cust['cst_gndr'] != 'n/a'
    df_cust['gender'] = df_cust['cst_gndr'].where(gender_cond, df_cust['gen'].fillna('n/a'))
    
    # Row Number: ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key
    df_cust = df_cust.sort_values(by='cst_id')
    df_cust['customer_key'] = range(1, len(df_cust) + 1)
    
    # Map final columns
    dim_cust_cols = {
        'customer_key': 'customer_key',
        'cst_id': 'customer_id',
        'cst_key': 'customer_number',
        'cst_firstname': 'first_name',
        'cst_lastname': 'last_name',
        'cntry': 'country',
        'cst_marital_status': 'marital_status',
        'gender': 'gender',
        'bdate': 'birthdate',
        'cst_create_date': 'create_date'
    }
    df_dim_customers = df_cust[list(dim_cust_cols.keys())].rename(columns=dim_cust_cols)
    
    dest_cust = os.path.join(gold_dir, "dim_customers.csv")
    df_dim_customers.to_csv(dest_cust, index=False)
    print(f">> Load Duration: {time.time() - start_time:.2f} seconds")
    print(f">> Rows Loaded: {len(df_dim_customers)}")
    print(">> -------------")

    # 2. Loading gold.dim_products
    start_time = time.time()
    print(">> Truncating & Inserting: gold.dim_products")
    
    # Filter: WHERE pn.prd_end_dt IS NULL
    # When reading from CSV, null date fields are NaN
    df_pn_filtered = df_pn[df_pn['prd_end_dt'].isna()].copy()
    
    # Align join keys
    df_pn_filtered['cat_id'] = df_pn_filtered['cat_id'].astype(str).str.strip()
    df_pc['id'] = df_pc['id'].astype(str).str.strip()
    
    # Merge datasets
    df_prod = df_pn_filtered.merge(df_pc, left_on='cat_id', right_on='id', how='left')
    
    # Row Number: ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key
    df_prod = df_prod.sort_values(by=['prd_start_dt', 'prd_key'])
    df_prod['product_key'] = range(1, len(df_prod) + 1)
    
    # Map final columns
    dim_prod_cols = {
        'product_key': 'product_key',
        'prd_id': 'product_id',
        'prd_key': 'product_number',
        'prd_nm': 'product_name',
        'cat_id': 'category_id',
        'cat': 'category',
        'subcat': 'subcategory',
        'maintenance': 'maintenance',
        'prd_cost': 'cost',
        'prd_line': 'product_line',
        'prd_start_dt': 'start_date'
    }
    df_dim_products = df_prod[list(dim_prod_cols.keys())].rename(columns=dim_prod_cols)
    
    dest_prod = os.path.join(gold_dir, "dim_products.csv")
    df_dim_products.to_csv(dest_prod, index=False)
    print(f">> Load Duration: {time.time() - start_time:.2f} seconds")
    print(f">> Rows Loaded: {len(df_dim_products)}")
    print(">> -------------")

    # 3. Loading gold.fact_sales
    start_time = time.time()
    print(">> Truncating & Inserting: gold.fact_sales")
    
    # Date trunc filter: WHERE DATE_TRUNC('month', sd.sls_order_dt) = DATE_TRUNC('month', CURRENT_DATE)
    df_sd['sls_order_dt_dt'] = pd.to_datetime(df_sd['sls_order_dt'], errors='coerce')
    today = pd.Timestamp.now()
    
    initial_rows = len(df_sd)
    if filter_current_month:
        df_sd_filtered = df_sd[
            (df_sd['sls_order_dt_dt'].dt.year == today.year) & 
            (df_sd['sls_order_dt_dt'].dt.month == today.month)
        ].copy()
        print(f">> Filter active: current month ({today.strftime('%Y-%m')}) only.")
        print(f">> Filtered sales details rows from {initial_rows} down to {len(df_sd_filtered)}.")
        if len(df_sd_filtered) == 0:
            print("WARNING: Replicated current-month filter is active and source data has no matches for the current real-world date.")
            print("         If you need to test with all historical dates, run: load_gold(filter_current_month=False)")
    else:
        df_sd_filtered = df_sd.copy()
        print(">> Filter inactive: loading all historical sales data.")
        
    # Align join keys
    df_sd_filtered['sls_prd_key'] = df_sd_filtered['sls_prd_key'].astype(str).str.strip()
    df_dim_products['product_number'] = df_dim_products['product_number'].astype(str).str.strip()
    
    df_sd_filtered['sls_cust_id'] = pd.to_numeric(df_sd_filtered['sls_cust_id'], errors='coerce')
    df_dim_customers['customer_id'] = pd.to_numeric(df_dim_customers['customer_id'], errors='coerce')
    
    # Merge datasets
    df_fact = df_sd_filtered.merge(df_dim_products, left_on='sls_prd_key', right_on='product_number', how='left')
    df_fact = df_fact.merge(df_dim_customers, left_on='sls_cust_id', right_on='customer_id', how='left')
    
    # Map final columns
    fact_cols = {
        'sls_ord_num': 'order_number',
        'product_key': 'product_key',
        'customer_key': 'customer_key',
        'sls_order_dt': 'order_date',
        'sls_ship_dt': 'shipping_date',
        'sls_due_dt': 'due_date',
        'sls_sales': 'sales_amount',
        'sls_quantity': 'quantity',
        'sls_price': 'price'
    }
    
    # Ensure missing keys remain Int64
    df_fact['product_key'] = df_fact['product_key'].astype('Int64')
    df_fact['customer_key'] = df_fact['customer_key'].astype('Int64')
    
    df_fact_sales = df_fact[list(fact_cols.keys())].rename(columns=fact_cols)
    
    dest_fact = os.path.join(gold_dir, "fact_sales.csv")
    df_fact_sales.to_csv(dest_fact, index=False)
    print(f">> Load Duration: {time.time() - start_time:.2f} seconds")
    print(f">> Rows Loaded: {len(df_fact_sales)}")
    print(">> -------------")

    batch_duration = time.time() - batch_start_time
    print("==========================================")
    print("Loading Gold Layer is Completed")
    print(f"   - Total Load Duration: {batch_duration:.2f} seconds")
    print("==========================================")

if __name__ == "__main__":
    load_gold()
