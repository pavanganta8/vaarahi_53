import os
import sys
import time
import argparse

# Add the project root to sys.path so we can import modules
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, ".."))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

# Import local pipeline procedures
try:
    from python.bronze.proc_load_bronze import load_bronze
    from python.silver.proc_load_silver import load_silver
    from python.gold.proc_load_gold import load_gold
except ImportError:
    # Fallback in case of execution context issues
    from bronze.proc_load_bronze import load_bronze
    from silver.proc_load_silver import load_silver
    from gold.proc_load_gold import load_gold

def main():
    parser = argparse.ArgumentParser(description="Run the Python Pandas DWH ETL Pipeline.")
    parser.add_argument(
        "--no-filter", 
        action="store_true", 
        help="Disable the current month filter on fact_sales to load all historical data."
    )
    args = parser.parse_args()

    print("======================================================================")
    print("STARTING PYTHON PANDAS ETL PIPELINE")
    print("======================================================================")
    
    pipeline_start = time.time()
    
    # 1. Run Bronze Load
    load_bronze(base_dir=project_root)
    
    # 2. Run Silver Load
    load_silver(base_dir=project_root)
    
    # 3. Run Gold Load
    # We replicate PGSQL logic (filter_current_month=True) unless user specifies --no-filter
    filter_current_month = not args.no_filter
    load_gold(base_dir=project_root, filter_current_month=filter_current_month)
    
    pipeline_duration = time.time() - pipeline_start
    print("======================================================================")
    print(f"PIPELINE COMPLETED SUCCESSFULLY IN {pipeline_duration:.2f} SECONDS")
    print("======================================================================")

if __name__ == "__main__":
    main()
