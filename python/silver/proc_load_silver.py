import os
import time
import pandas as pd
import numpy as np

def load_silver(base_dir=None):
    """
    Simulates the silver.load_silver stored procedure.
    Reads data from python/datasets/bronze/, cleans and transforms it,
    and writes it to python/datasets/silver/.
    """
    if base_dir is None:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.abspath(os.path.join(script_dir, "..", ".."))
    else:
        project_root = os.path.abspath(base_dir)

    bronze_dir = os.path.join(project_root, "python", "datasets", "bronze")
    silver_dir = os.path.join(project_root, "python", "datasets", "silver")
    os.makedirs(silver_dir, exist_ok=True)

    print("================================================")
    print("Loading Silver Layer")
    print("================================================")
    batch_start_time = time.time()

    print("------------------------------------------------")
    print("Loading CRM Tables")
    print("------------------------------------------------")

    # 1. Loading crm_cust_info
    start_time = time.time()
    print(">> Inserting Data Into: silver.crm_cust_info")
    cust_path = os.path.join(bronze_dir, "crm_cust_info.csv")
    if os.path.exists(cust_path):
        df_cust = pd.read_csv(cust_path)
        df_cust.columns = df_cust.columns.str.lower()
        
        # Filter where cst_id is not null
        df_cust = df_cust[df_cust["cst_id"].notna()]
        
        # De-duplicate: ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC)
        df_cust["cst_create_date"] = pd.to_datetime(df_cust["cst_create_date"], format='mixed', errors='coerce')
        df_cust = df_cust.sort_values(by=["cst_id", "cst_create_date"], ascending=[True, False])
        df_cust = df_cust.drop_duplicates(subset=["cst_id"], keep="first")
        
        # Trims
        df_cust["cst_firstname"] = df_cust["cst_firstname"].astype(str).str.strip()
        df_cust["cst_lastname"] = df_cust["cst_lastname"].astype(str).str.strip()
        
        # Map marital status
        df_cust["cst_marital_status"] = df_cust["cst_marital_status"].astype(str).str.strip().str.upper().map({
            "S": "Single",
            "M": "Married"
        }).fillna("n/a")
        
        # Map gender
        df_cust["cst_gndr"] = df_cust["cst_gndr"].astype(str).str.strip().str.upper().map({
            "F": "Female",
            "M": "Male"
        }).fillna("n/a")
        
        # Add metadata
        df_cust["dwh_create_date"] = pd.Timestamp.now()
        
        dest_cust_path = os.path.join(silver_dir, "crm_cust_info.csv")
        df_cust.to_csv(dest_cust_path, index=False)
        print(f">> Load Duration: {time.time() - start_time:.2f} seconds")
        print(f">> Rows Loaded: {len(df_cust)}")
    else:
        print(f"WARNING: Bronze crm_cust_info not found at {cust_path}")
    print(">> -------------")

    # 2. Loading crm_prd_info
    start_time = time.time()
    print(">> Inserting Data Into: silver.crm_prd_info")
    prd_path = os.path.join(bronze_dir, "crm_prd_info.csv")
    if os.path.exists(prd_path):
        df_prd = pd.read_csv(prd_path)
        df_prd.columns = df_prd.columns.str.lower()
        
        # Ensure dates are datetime for lead calculation
        df_prd["prd_start_dt"] = pd.to_datetime(df_prd["prd_start_dt"], format='mixed', errors='coerce')
        
        # Window function: LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 day
        df_prd = df_prd.sort_values(by=["prd_key", "prd_start_dt"])
        df_prd["prd_end_dt"] = df_prd.groupby("prd_key")["prd_start_dt"].shift(-1) - pd.Timedelta(days=1)
        
        # Extract cat_id: REPLACE(SUBSTRING(prd_key FROM 1 FOR 5), '-', '_')
        df_prd["cat_id"] = df_prd["prd_key"].str[:5].str.replace("-", "_")
        
        # Clean prd_key: SUBSTRING(prd_key FROM 7)
        df_prd["prd_key"] = df_prd["prd_key"].str[6:]
        
        # Handle product cost: COALESCE(prd_cost, 0)
        df_prd["prd_cost"] = df_prd["prd_cost"].fillna(0).astype(int)
        
        # Map product line
        df_prd["prd_line"] = df_prd["prd_line"].astype(str).str.strip().str.upper().map({
            "M": "Mountain",
            "R": "Road",
            "S": "Other Sales",
            "T": "Touring"
        }).fillna("n/a")
        
        # Format start/end dates
        df_prd["prd_start_dt"] = df_prd["prd_start_dt"].dt.date
        # Keep end date as date (with NaT for NaNs)
        df_prd["prd_end_dt"] = df_prd["prd_end_dt"].dt.date
        
        # Add metadata
        df_prd["dwh_create_date"] = pd.Timestamp.now()
        
        # Select & reorder columns to match DDL: prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt, dwh_create_date
        cols = ["prd_id", "cat_id", "prd_key", "prd_nm", "prd_cost", "prd_line", "prd_start_dt", "prd_end_dt", "dwh_create_date"]
        df_prd = df_prd[cols]
        
        dest_prd_path = os.path.join(silver_dir, "crm_prd_info.csv")
        df_prd.to_csv(dest_prd_path, index=False)
        print(f">> Load Duration: {time.time() - start_time:.2f} seconds")
        print(f">> Rows Loaded: {len(df_prd)}")
    else:
        print(f"WARNING: Bronze crm_prd_info not found at {prd_path}")
    print(">> -------------")

    # 3. Loading crm_sales_details
    start_time = time.time()
    print(">> Inserting Data Into: silver.crm_sales_details")
    sales_path = os.path.join(bronze_dir, "crm_sales_details.csv")
    if os.path.exists(sales_path):
        df_sales = pd.read_csv(sales_path)
        df_sales.columns = df_sales.columns.str.lower()
        
        # Handle date parsing
        for col in ["sls_order_dt", "sls_ship_dt", "sls_due_dt"]:
            # Convert float/int to standard string representing int
            s = df_sales[col].fillna(0).astype(int).astype(str)
            # Match TO_DATE(CAST(val AS VARCHAR), 'YYYYMMDD') where length = 8 and val != 0
            parsed_date = pd.to_datetime(s, format="%Y%m%d", errors="coerce")
            df_sales[col] = parsed_date.where((s.str.len() == 8) & (s != "0"), pd.NaT).dt.date
            
        # Convert columns to Int64 to handle nullable integers correctly
        df_sales["sls_quantity"] = df_sales["sls_quantity"].astype("Int64")
        df_sales["sls_sales"] = df_sales["sls_sales"].astype("Int64")
        df_sales["sls_price"] = df_sales["sls_price"].astype("Int64")
        
        # Sales amount validation
        expected_sales = df_sales["sls_quantity"] * df_sales["sls_price"].abs()
        sales_mask = df_sales["sls_sales"].isna() | (df_sales["sls_sales"] <= 0) | (df_sales["sls_sales"] != expected_sales)
        df_sales.loc[sales_mask, "sls_sales"] = expected_sales
        
        # Price validation
        price_mask = df_sales["sls_price"].isna() | (df_sales["sls_price"] <= 0)
        divisor = df_sales["sls_quantity"].astype(float).replace(0, np.nan)
        calculated_price = (df_sales["sls_sales"].astype(float) / divisor).round().astype("Int64")
        df_sales.loc[price_mask, "sls_price"] = calculated_price
        
        # Re-ensure types are Int64
        df_sales["sls_sales"] = df_sales["sls_sales"].astype("Int64")
        df_sales["sls_price"] = df_sales["sls_price"].astype("Int64")
        
        # Add metadata
        df_sales["dwh_create_date"] = pd.Timestamp.now()
        
        dest_sales_path = os.path.join(silver_dir, "crm_sales_details.csv")
        df_sales.to_csv(dest_sales_path, index=False)
        print(f">> Load Duration: {time.time() - start_time:.2f} seconds")
        print(f">> Rows Loaded: {len(df_sales)}")
    else:
        print(f"WARNING: Bronze crm_sales_details not found at {sales_path}")
    print(">> -------------")

    print("------------------------------------------------")
    print("Loading ERP Tables")
    print("------------------------------------------------")

    # 4. Loading erp_cust_az12
    start_time = time.time()
    print(">> Inserting Data Into: silver.erp_cust_az12")
    erp_cust_path = os.path.join(bronze_dir, "erp_cust_az12.csv")
    if os.path.exists(erp_cust_path):
        df_ecust = pd.read_csv(erp_cust_path)
        df_ecust.columns = df_ecust.columns.str.lower()
        
        # Clean cid: if starts with 'NAS', remove 'NAS'
        df_ecust["cid"] = df_ecust["cid"].astype(str).apply(lambda x: x[3:] if x.startswith("NAS") else x)
        
        # Clean bdate: if in the future, set to NaT/None
        df_ecust["bdate"] = pd.to_datetime(df_ecust["bdate"], format='mixed', errors='coerce')
        today = pd.Timestamp.now().normalize()
        df_ecust.loc[df_ecust["bdate"] > today, "bdate"] = pd.NaT
        df_ecust["bdate"] = df_ecust["bdate"].dt.date
        
        # Map gender
        df_ecust["gen"] = df_ecust["gen"].astype(str).str.strip().str.upper().map({
            "F": "Female",
            "FEMALE": "Female",
            "M": "Male",
            "MALE": "Male"
        }).fillna("n/a")
        
        # Add metadata
        df_ecust["dwh_create_date"] = pd.Timestamp.now()
        
        dest_ecust_path = os.path.join(silver_dir, "erp_cust_az12.csv")
        df_ecust.to_csv(dest_ecust_path, index=False)
        print(f">> Load Duration: {time.time() - start_time:.2f} seconds")
        print(f">> Rows Loaded: {len(df_ecust)}")
    else:
        print(f"WARNING: Bronze erp_cust_az12 not found at {erp_cust_path}")
    print(">> -------------")

    # 5. Loading erp_loc_a101
    start_time = time.time()
    print(">> Inserting Data Into: silver.erp_loc_a101")
    loc_path = os.path.join(bronze_dir, "erp_loc_a101.csv")
    if os.path.exists(loc_path):
        df_loc = pd.read_csv(loc_path)
        df_loc.columns = df_loc.columns.str.lower()
        
        # Clean cid: remove hyphens
        df_loc["cid"] = df_loc["cid"].astype(str).str.replace("-", "")
        
        # Map countries
        df_loc["cntry"] = df_loc["cntry"].astype(str).str.strip()
        df_loc["cntry"] = df_loc["cntry"].replace({
            "DE": "Germany",
            "US": "United States",
            "USA": "United States",
            "": "n/a",
            "nan": "n/a"
        }).fillna("n/a")
        
        # Add metadata
        df_loc["dwh_create_date"] = pd.Timestamp.now()
        
        dest_loc_path = os.path.join(silver_dir, "erp_loc_a101.csv")
        df_loc.to_csv(dest_loc_path, index=False)
        print(f">> Load Duration: {time.time() - start_time:.2f} seconds")
        print(f">> Rows Loaded: {len(df_loc)}")
    else:
        print(f"WARNING: Bronze erp_loc_a101 not found at {loc_path}")
    print(">> -------------")

    # 6. Loading erp_px_cat_g1v2
    start_time = time.time()
    print(">> Inserting Data Into: silver.erp_px_cat_g1v2")
    cat_path = os.path.join(bronze_dir, "erp_px_cat_g1v2.csv")
    if os.path.exists(cat_path):
        df_cat = pd.read_csv(cat_path)
        df_cat.columns = df_cat.columns.str.lower()
        
        # Add metadata
        df_cat["dwh_create_date"] = pd.Timestamp.now()
        
        dest_cat_path = os.path.join(silver_dir, "erp_px_cat_g1v2.csv")
        df_cat.to_csv(dest_cat_path, index=False)
        print(f">> Load Duration: {time.time() - start_time:.2f} seconds")
        print(f">> Rows Loaded: {len(df_cat)}")
    else:
        print(f"WARNING: Bronze erp_px_cat_g1v2 not found at {cat_path}")
    print(">> -------------")

    batch_duration = time.time() - batch_start_time
    print("==========================================")
    print("Loading Silver Layer is Completed")
    print(f"   - Total Load Duration: {batch_duration:.2f} seconds")
    print("==========================================")

if __name__ == "__main__":
    load_silver()
