-- =========================================================================
-- PROJECT FILE: 03_load_silver_procedure.sql
-- DESCRIPTION: Implements the ETL logic to load and cleanse data from bronze 
--              to silver. Uses all major PL/pgSQL procedural concepts.
-- CONCEPTS USED:
--   1. Variables & Data Types (Timestamps, Counters, Arrays)
--   2. IF-ELSE Conditional Logic (Data quality checks, integrity enforcement)
--   3. FOR Loop (Iterating over query results for summary logs)
--   4. WHILE Loop (Executing post-load verification checklist)
--   5. Exceptions (Isolating errors using sub-blocks & logging details)
--   6. Cursors (Row-by-row fetching for complex fact table mapping)
--   7. Functions (Modular data cleaning helper functions)
--   8. Triggers (Automatic timestamp and audit triggers)
-- =========================================================================

-- ==========================================
-- A. HELPER FUNCTIONS (Concept 7: Functions)
-- ==========================================

-- 1. Function to clean and standardize gender values
CREATE OR REPLACE FUNCTION silver.clean_gender(p_gender_str TEXT)
RETURNS VARCHAR 
LANGUAGE plpgsql
AS $$
DECLARE
    v_gender_clean TEXT;
BEGIN
    IF p_gender_str IS NULL THEN
        RETURN 'n/a';
    END IF;
    
    v_gender_clean := LOWER(TRIM(p_gender_str));
    
    -- standardizing input categories
    IF v_gender_clean IN ('m', 'male') THEN
        RETURN 'Male';
    ELSIF v_gender_clean IN ('f', 'female') THEN
        RETURN 'Female';
    ELSE
        RETURN 'n/a'; -- Default fallback
    END IF;
END;
$$;


-- 2. Function to safely clean currency formatting and parse to numeric
CREATE OR REPLACE FUNCTION silver.clean_price(p_price_str TEXT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_numeric_str TEXT;
BEGIN
    -- Handle missing or free values
    IF p_price_str IS NULL OR TRIM(p_price_str) = '' OR LOWER(TRIM(p_price_str)) = 'free' THEN
        RETURN 0.00;
    END IF;
    
    -- Remove dollar symbols or extraneous spaces
    v_numeric_str := REPLACE(TRIM(p_price_str), '$', '');
    
    -- Safe conversion block
    BEGIN
        RETURN CAST(v_numeric_str AS NUMERIC(10, 2));
    EXCEPTION WHEN OTHERS THEN
        RETURN 0.00; -- Return fallback if parsing fails
    END;
END;
$$;


-- 3. Function to dynamically parse multiple date formats safely
CREATE OR REPLACE FUNCTION silver.parse_date_safe(p_date_str TEXT)
RETURNS DATE
LANGUAGE plpgsql
AS $$
DECLARE
    v_parsed_date DATE;
BEGIN
    IF p_date_str IS NULL OR TRIM(p_date_str) = '' THEN
        RETURN NULL;
    END IF;
    
    -- Attempt YYYY-MM-DD
    BEGIN
        v_parsed_date := TO_DATE(TRIM(p_date_str), 'YYYY-MM-DD');
        RETURN v_parsed_date;
    EXCEPTION WHEN OTHERS THEN
        -- Fallback to DD-MM-YYYY
        BEGIN
            v_parsed_date := TO_DATE(TRIM(p_date_str), 'DD-MM-YYYY');
            RETURN v_parsed_date;
        EXCEPTION WHEN OTHERS THEN
            -- Fallback to YYYY/MM/DD
            BEGIN
                v_parsed_date := TO_DATE(TRIM(p_date_str), 'YYYY/MM/DD');
                RETURN v_parsed_date;
            EXCEPTION WHEN OTHERS THEN
                RETURN NULL; -- Return null if parsing fails
            END;
        END;
    END;
END;
$$;


-- ==========================================
-- B. TRIGGERS (Concept 8: Triggers)
-- ==========================================

-- Trigger function to automatically update updated_at timestamp on record modification
CREATE OR REPLACE FUNCTION silver.trg_update_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Bind trigger to silver.dim_customer
CREATE OR REPLACE TRIGGER trg_customer_update_stamp
BEFORE UPDATE ON silver.dim_customer
FOR EACH ROW
EXECUTE FUNCTION silver.trg_update_timestamp();

-- Bind trigger to silver.dim_products
CREATE OR REPLACE TRIGGER trg_product_update_stamp
BEFORE UPDATE ON silver.dim_products
FOR EACH ROW
EXECUTE FUNCTION silver.trg_update_timestamp();


-- ===================================================
-- C. MAIN STORED PROCEDURE (Concepts 1-6 integration)
-- ===================================================

CREATE OR REPLACE PROCEDURE silver.load_silver_data()
LANGUAGE plpgsql
AS $$
DECLARE
    -- 1. Variables and Data Types declaration (Concept 1)
    v_proc_name      CONSTANT VARCHAR(100) := 'silver.load_silver_data';
    v_run_start_time TIMESTAMP := CURRENT_TIMESTAMP;
    v_step_start     TIMESTAMP;
    v_step_end       TIMESTAMP;
    v_inserted_rows  INTEGER := 0;
    
    -- Declaring variables for cursors and table checklists
    v_check_index    INTEGER := 1;
    v_check_table    VARCHAR(100);
    v_check_count    INTEGER;
    v_log_record     RECORD;
    
    -- Variables for validating each row fetched from cursor
    v_cust_key       INTEGER;
    v_prod_key       INTEGER;
    v_cleaned_price  NUMERIC;
    v_parsed_qty     INTEGER;
    v_total_price    NUMERIC;
    v_parsed_date    DATE;
    
    -- 2. Cursor declaration (Concept 6)
    -- This cursor is used to process raw sales from bronze row-by-row
    c_sales_cursor CURSOR FOR
        SELECT sale_id, cust_id, prod_id, qty, sale_date 
        FROM bronze.sales;
        
BEGIN
    RAISE NOTICE 'Starting ETL pipeline from Bronze to Silver...';
    
    -- Log pipeline start
    INSERT INTO audit.load_logs (procedure_name, step_name, status, error_message)
    VALUES (v_proc_name, 'START_PIPELINE', 'INFO', 'Pipeline loading sequence initiated.');

    -- =========================================================================
    -- STEP 1: Load Dimension Customer (Uses EXCEPTION sub-blocks - Concept 5)
    -- =========================================================================
    BEGIN
        v_step_start := CURRENT_TIMESTAMP;
        RAISE NOTICE 'Step 1: Loading silver.dim_customer...';
        
   
        
        -- Ingest and clean customer records
        INSERT INTO silver.dim_customer (cust_id, first_name, last_name, email, gender, created_date)
        SELECT 
            CAST(TRIM(cust_id) AS INTEGER) AS cust_id,
            -- Split names into first and last name
            TRIM(SPLIT_PART(cust_name, ' ', 1)) AS first_name,
            TRIM(SPLIT_PART(cust_name, ' ', 2)) AS last_name,
            LOWER(TRIM(email)) AS email,
            silver.clean_gender(gender) AS gender, -- Using standardizing function
            silver.parse_date_safe(created_date) AS created_date -- Using flexible date parser
        FROM bronze.customer
        WHERE cust_id IS NOT NULL 
          AND cust_id ~ '^[0-9]+$' -- Ensure it is a valid integer string
          AND cust_name IS NOT NULL AND TRIM(cust_name) != '';
          
        GET DIAGNOSTICS v_inserted_rows = ROW_COUNT;
        
        -- Log success
        INSERT INTO audit.load_logs (procedure_name, step_name, status, records_loaded)
        VALUES (v_proc_name, 'LOAD_DIM_CUSTOMER', 'SUCCESS', v_inserted_rows);
        
    EXCEPTION WHEN OTHERS THEN
        -- Handles errors locally without crashing the remaining tables execution (Concept 5)
        INSERT INTO audit.load_logs (procedure_name, step_name, status, error_message, error_state)
        VALUES (v_proc_name, 'LOAD_DIM_CUSTOMER', 'FAILED', SQLERRM, SQLSTATE);
        RAISE WARNING 'Failed to load dim_customer: %', SQLERRM;
    END;


    -- =========================================================================
    -- STEP 2: Load Dimension Products (Uses EXCEPTION sub-blocks - Concept 5)
    -- =========================================================================
    BEGIN
        v_step_start := CURRENT_TIMESTAMP;
        RAISE NOTICE 'Step 2: Loading silver.dim_products...';
        
     
        
        -- Ingest and clean product records
        INSERT INTO silver.dim_products (prod_id, prod_name, category, price)
        SELECT 
            CAST(TRIM(prod_id) AS INTEGER) AS prod_id,
            TRIM(prod_name) AS prod_name,
            TRIM(category) AS category,
            silver.clean_price(price) AS price -- Parse formatted price currency strings
        FROM bronze.products
        WHERE prod_id IS NOT NULL 
          AND prod_id ~ '^[0-9]+$' -- Ensure it is a valid integer string
          -- Ignore broken rows with non-functional names/categories
          AND prod_name IS NOT NULL AND TRIM(prod_name) != '';
          
        GET DIAGNOSTICS v_inserted_rows = ROW_COUNT;
        
        -- Log success
        INSERT INTO audit.load_logs (procedure_name, step_name, status, records_loaded)
        VALUES (v_proc_name, 'LOAD_DIM_PRODUCTS', 'SUCCESS', v_inserted_rows);
        
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO audit.load_logs (procedure_name, step_name, status, error_message, error_state)
        VALUES (v_proc_name, 'LOAD_DIM_PRODUCTS', 'FAILED', SQLERRM, SQLSTATE);
        RAISE WARNING 'Failed to load dim_products: %', SQLERRM;
    END;


    -- =========================================================================
    -- STEP 3: Load Fact Product Sales (Uses Cursors, IF-ELSE, & Exceptions - Concept 6, 2, 5)
    -- =========================================================================
    BEGIN
        v_step_start := CURRENT_TIMESTAMP;
        RAISE NOTICE 'Step 3: Loading silver.fact_products_sales...';
        
        TRUNCATE TABLE silver.fact_products_sales;
        v_inserted_rows := 0;
        
        -- Open cursor to traverse through sales row-by-row
        OPEN c_sales_cursor;
        
        LOOP
            -- Fetch current cursor row into variable records
            FETCH c_sales_cursor INTO v_log_record;
            EXIT WHEN NOT FOUND; -- Exit loop condition
            
            -- Validation & Mapping logic (Concept 2: IF-ELSE)
            -- 1. Find Customer Surrogate Key
            SELECT customer_key INTO v_cust_key 
            FROM silver.dim_customer 
            WHERE cust_id = CAST(TRIM(v_log_record.cust_id) AS INTEGER);
            
            -- 2. Find Product Surrogate Key and Price
            SELECT product_key, price INTO v_prod_key, v_cleaned_price
            FROM silver.dim_products 
            WHERE prod_id = CAST(TRIM(v_log_record.prod_id) AS INTEGER);
            
            -- 3. Parse and clean Quantity
            BEGIN
                v_parsed_qty := CAST(TRIM(v_log_record.qty) AS INTEGER);
            EXCEPTION WHEN OTHERS THEN
                v_parsed_qty := NULL; -- If quantity is corrupt, set to null
            END;
            
            -- Parse Date
            v_parsed_date := silver.parse_date_safe(v_log_record.sale_date);

            -- Concept 2: IF-ELSE to enforce Business & Referential Integrity rules
            IF v_cust_key IS NULL THEN
                RAISE WARNING 'Skipping sale_id %: Customer ID % does not exist in silver.dim_customer', v_log_record.sale_id, v_log_record.cust_id;
            ELSIF v_prod_key IS NULL THEN
                RAISE WARNING 'Skipping sale_id %: Product ID % does not exist in silver.dim_products', v_log_record.sale_id, v_log_record.prod_id;
            ELSIF v_parsed_qty IS NULL OR v_parsed_qty <= 0 THEN
                RAISE WARNING 'Skipping sale_id %: Invalid quantity value (%s)', v_log_record.sale_id, v_log_record.qty;
            ELSIF v_parsed_date IS NULL THEN
                RAISE WARNING 'Skipping sale_id %: Invalid sale date value (%s)', v_log_record.sale_id, v_log_record.sale_date;
            ELSE
                -- All validations passed! Calculate total price and insert into fact table
                v_total_price := v_parsed_qty * v_cleaned_price;
                
                INSERT INTO silver.fact_products_sales (sale_id, customer_key, product_key, qty, total_price, sale_date)
                VALUES (
                    CAST(TRIM(v_log_record.sale_id) AS INTEGER), 
                    v_cust_key, 
                    v_prod_key, 
                    v_parsed_qty, 
                    v_total_price, 
                    v_parsed_date
                );
                
                v_inserted_rows := v_inserted_rows + 1;
            END IF;
            
        END LOOP;
        
        CLOSE c_sales_cursor; -- Close cursor
        
        -- Log success
        INSERT INTO audit.load_logs (procedure_name, step_name, status, records_loaded)
        VALUES (v_proc_name, 'LOAD_FACT_SALES', 'SUCCESS', v_inserted_rows);
        
    EXCEPTION WHEN OTHERS THEN
        IF c_sales_cursor%ISOPEN THEN
            CLOSE c_sales_cursor;
        END IF;
        INSERT INTO audit.load_logs (procedure_name, step_name, status, error_message, error_state)
        VALUES (v_proc_name, 'LOAD_FACT_SALES', 'FAILED', SQLERRM, SQLSTATE);
        RAISE WARNING 'Failed to load fact_sales: %', SQLERRM;
    END;


    -- =========================================================================
    -- STEP 4: Post-Load Table Validation checklist (Concept 4: WHILE Loop)
    -- =========================================================================
    RAISE NOTICE '--- Post Load Verification checklist ---';
    v_check_index := 1;
    
    WHILE v_check_index <= 3 LOOP
        -- Select table based on iteration index
        IF v_check_index = 1 THEN
            v_check_table := 'silver.dim_customer';
        ELSIF v_check_index = 2 THEN
            v_check_table := 'silver.dim_products';
        ELSE
            v_check_table := 'silver.fact_products_sales';
        END IF;
        
        -- Count rows inside table dynamically
        EXECUTE 'SELECT COUNT(*) FROM ' || v_check_table INTO v_check_count;
        
        IF v_check_count = 0 THEN
            RAISE WARNING 'Check Failed: % has 0 rows!', v_check_table;
        ELSE
            RAISE NOTICE 'Check Passed: % contains % records.', v_check_table, v_check_count;
        END IF;
        
        v_check_index := v_check_index + 1; -- Increment index loop
    END LOOP;


    -- =========================================================================
    -- STEP 5: Print Summary Report of Load Logs (Concept 3: FOR Loop)
    -- =========================================================================
    RAISE NOTICE '==================================================';
    RAISE NOTICE 'ETL COMPLETED. CURRENT PIPELINE EXECUTION SUMMARY:';
    RAISE NOTICE '==================================================';
    
    FOR v_log_record IN (
        SELECT step_name, status, records_loaded, error_message 
        FROM audit.load_logs 
        WHERE logged_at >= v_run_start_time
        ORDER BY log_id ASC
    ) LOOP
        IF v_log_record.status = 'SUCCESS' THEN
            RAISE NOTICE '>> STEP: % | STATUS: % | RECORDS LOADED: %', 
                RPAD(v_log_record.step_name, 22, ' '), 
                v_log_record.status, 
                v_log_record.records_loaded;
        ELSIF v_log_record.status = 'FAILED' THEN
            RAISE WARNING '>> STEP: % | STATUS: % | ERROR: %', 
                RPAD(v_log_record.step_name, 22, ' '), 
                v_log_record.status, 
                v_log_record.error_message;
        ELSE
            RAISE NOTICE '>> STEP: % | STATUS: % | %', 
                RPAD(v_log_record.step_name, 22, ' '), 
                v_log_record.status, 
                v_log_record.error_message;
        END IF;
    END LOOP;
    
    RAISE NOTICE '==================================================';

END;
$$;
