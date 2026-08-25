-- =========================================================================
-- PROCEDURE: silver.load_dim_customer
-- DESCRIPTION: Cleanses and loads customer records from bronze.customer to silver.dim_customer.
--              Demonstrates basic sub-block exception handling.
-- =========================================================================

CREATE OR REPLACE PROCEDURE silver.load_dim_customer(
    p_proc_name VARCHAR,
    OUT p_inserted_rows INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_inserted_rows := 0;
    
    -- Idempotency: Clear existing customers (Using DELETE to avoid CASCADE issues)
    DELETE FROM silver.dim_customer;

    -- Ingest and clean customer records
    INSERT INTO silver.dim_customer (cust_id, first_name, last_name, email, gender, created_date)
    SELECT 
        CAST(TRIM(cust_id) AS INTEGER) AS cust_id,
        TRIM(SPLIT_PART(cust_name, ' ', 1)) AS first_name,
        TRIM(SPLIT_PART(cust_name, ' ', 2)) AS last_name,
        LOWER(TRIM(email)) AS email,
        silver.clean_gender(gender) AS gender,
        silver.parse_date_safe(created_date) AS created_date
    FROM bronze.customer
    WHERE cust_id IS NOT NULL 
      AND cust_id ~ '^[0-9]+$'
      AND cust_name IS NOT NULL AND TRIM(cust_name) != '';
      
    GET DIAGNOSTICS p_inserted_rows = ROW_COUNT;
    
    -- Log success
    INSERT INTO audit.load_logs (procedure_name, step_name, status, records_loaded)
    VALUES (p_proc_name, 'LOAD_DIM_CUSTOMER', 'SUCCESS', p_inserted_rows);
    
EXCEPTION WHEN OTHERS THEN
    -- Log failure and raise warning
    INSERT INTO audit.load_logs (procedure_name, step_name, status, error_message, error_state)
    VALUES (p_proc_name, 'LOAD_DIM_CUSTOMER', 'FAILED', SQLERRM, SQLSTATE);
    RAISE WARNING 'Failed to load dim_customer: %', SQLERRM;
END;
$$;
