-- =========================================================================
-- PROCEDURE: silver.load_fact_sales
-- DESCRIPTION: Loads and maps fact sales from bronze.sales to silver.fact_products_sales.
--              Demonstrates Cursors, Variables, and IF-ELSE Logic.
-- =========================================================================

CREATE OR REPLACE PROCEDURE silver.load_fact_sales(
    p_proc_name VARCHAR,
    OUT p_inserted_rows INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    -- Cursor declaration
    c_sales_cursor CURSOR FOR
        SELECT sale_id, cust_id, prod_id, qty, sale_date 
        FROM bronze.sales;
        
    -- Variables for processing
    v_log_record     RECORD;
    v_cust_key       INTEGER;
    v_prod_key       INTEGER;
    v_cleaned_price  NUMERIC;
    v_parsed_qty     INTEGER;
    v_total_price    NUMERIC;
    v_parsed_date    DATE;
BEGIN
    p_inserted_rows := 0;
    
    -- Idempotency: Clear existing sales
    DELETE FROM silver.fact_products_sales;
    
    -- Open cursor
    OPEN c_sales_cursor;
    
    LOOP
        FETCH c_sales_cursor INTO v_log_record;
        EXIT WHEN NOT FOUND;
        
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
            v_parsed_qty := NULL;
        END;
        
        -- 4. Parse Date
        v_parsed_date := silver.parse_date_safe(v_log_record.sale_date);

        -- IF-ELSE validations (Referential integrity, data formatting check)
        IF v_cust_key IS NULL THEN
            RAISE WARNING 'Skipping sale_id %: Customer ID % does not exist in silver.dim_customer', v_log_record.sale_id, v_log_record.cust_id;
        ELSIF v_prod_key IS NULL THEN
            RAISE WARNING 'Skipping sale_id %: Product ID % does not exist in silver.dim_products', v_log_record.sale_id, v_log_record.prod_id;
        ELSIF v_parsed_qty IS NULL OR v_parsed_qty <= 0 THEN
            RAISE WARNING 'Skipping sale_id %: Invalid quantity value (%s)', v_log_record.sale_id, v_log_record.qty;
        ELSIF v_parsed_date IS NULL THEN
            RAISE WARNING 'Skipping sale_id %: Invalid sale date value (%s)', v_log_record.sale_id, v_log_record.sale_date;
        ELSE
            -- All checks pass, calculate and insert
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
            
            p_inserted_rows := p_inserted_rows + 1;
        END IF;
        
    END LOOP;
    
    CLOSE c_sales_cursor;
    
    -- Log success
    INSERT INTO audit.load_logs (procedure_name, step_name, status, records_loaded)
    VALUES (p_proc_name, 'LOAD_FACT_SALES', 'SUCCESS', p_inserted_rows);
    
EXCEPTION WHEN OTHERS THEN
    IF c_sales_cursor%ISOPEN THEN
        CLOSE c_sales_cursor;
    END IF;
    INSERT INTO audit.load_logs (procedure_name, step_name, status, error_message, error_state)
    VALUES (p_proc_name, 'LOAD_FACT_SALES', 'FAILED', SQLERRM, SQLSTATE);
    RAISE WARNING 'Failed to load fact_sales: %', SQLERRM;
END;
$$;
