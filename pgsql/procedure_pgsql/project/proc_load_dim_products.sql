-- =========================================================================
-- PROCEDURE: silver.load_dim_products
-- DESCRIPTION: Cleanses and loads product records from bronze.products to silver.dim_products.
--              Demonstrates basic sub-block exception handling.
-- =========================================================================

CREATE OR REPLACE PROCEDURE silver.load_dim_products(
    p_proc_name VARCHAR,
    OUT p_inserted_rows INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_inserted_rows := 0;

    -- Idempotency: Clear existing products (Using DELETE to avoid CASCADE issues)
    DELETE FROM silver.dim_products;

    -- Ingest and clean product records
    INSERT INTO silver.dim_products (prod_id, prod_name, category, price)
    SELECT 
        CAST(TRIM(prod_id) AS INTEGER) AS prod_id,
        TRIM(prod_name) AS prod_name,
        TRIM(category) AS category,
        silver.clean_price(price) AS price
    FROM bronze.products
    WHERE prod_id IS NOT NULL 
      AND prod_id ~ '^[0-9]+$'
      AND prod_name IS NOT NULL AND TRIM(prod_name) != '';
      
    GET DIAGNOSTICS p_inserted_rows = ROW_COUNT;
    
    -- Log success
    INSERT INTO audit.load_logs (procedure_name, step_name, status, records_loaded)
    VALUES (p_proc_name, 'LOAD_DIM_PRODUCTS', 'SUCCESS', p_inserted_rows);
    
EXCEPTION WHEN OTHERS THEN
    -- Log failure and raise warning
    INSERT INTO audit.load_logs (procedure_name, step_name, status, error_message, error_state)
    VALUES (p_proc_name, 'LOAD_DIM_PRODUCTS', 'FAILED', SQLERRM, SQLSTATE);
    RAISE WARNING 'Failed to load dim_products: %', SQLERRM;
END;
$$;
