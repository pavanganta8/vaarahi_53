-- =========================================================================
-- PROCEDURE: silver.load_silver_data
-- DESCRIPTION: Master orchestrator procedure. Sequentially triggers individual
--              cleanse procedures, runs count validations, and prints summaries.
-- CONCEPTS SHOWN: Main Orchestration, Variable declaration, Sub-block Exceptions.
-- =========================================================================

CREATE OR REPLACE PROCEDURE silver.load_silver_data()
LANGUAGE plpgsql
AS $$
DECLARE
    -- Variable declaration
    v_proc_name      CONSTANT VARCHAR(100) := 'silver.load_silver_data';
    v_run_start_time TIMESTAMP := CURRENT_TIMESTAMP;
    v_inserted_rows  INTEGER := 0;
BEGIN
    RAISE NOTICE 'Starting Orchestrated ETL pipeline from Bronze to Silver...';
    
    -- Log pipeline start
    INSERT INTO audit.load_logs (procedure_name, step_name, status, error_message)
    VALUES (v_proc_name, 'START_PIPELINE', 'INFO', 'Pipeline loading sequence initiated.');

    -- =========================================================================
    -- STEP 1: Load Dimension Customer (Isolating Exceptions)
    -- =========================================================================
    BEGIN
        CALL silver.load_dim_customer(v_proc_name, v_inserted_rows);
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO audit.load_logs (procedure_name, step_name, status, error_message, error_state)
        VALUES (v_proc_name, 'LOAD_DIM_CUSTOMER_ORCHESTRATOR', 'FAILED', SQLERRM, SQLSTATE);
        RAISE WARNING 'Master orchestrator caught dim_customer failure: %', SQLERRM;
    END;

    -- =========================================================================
    -- STEP 2: Load Dimension Products (Isolating Exceptions)
    -- =========================================================================
    BEGIN
        CALL silver.load_dim_products(v_proc_name, v_inserted_rows);
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO audit.load_logs (procedure_name, step_name, status, error_message, error_state)
        VALUES (v_proc_name, 'LOAD_DIM_PRODUCTS_ORCHESTRATOR', 'FAILED', SQLERRM, SQLSTATE);
        RAISE WARNING 'Master orchestrator caught dim_products failure: %', SQLERRM;
    END;

    -- =========================================================================
    -- STEP 3: Load Fact Product Sales (Isolating Exceptions)
    -- =========================================================================
    BEGIN
        CALL silver.load_fact_sales(v_proc_name, v_inserted_rows);
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO audit.load_logs (procedure_name, step_name, status, error_message, error_state)
        VALUES (v_proc_name, 'LOAD_FACT_SALES_ORCHESTRATOR', 'FAILED', SQLERRM, SQLSTATE);
        RAISE WARNING 'Master orchestrator caught fact_sales failure: %', SQLERRM;
    END;

    -- =========================================================================
    -- STEP 4: Post-Load Table Validation (WHILE Loop Procedure)
    -- =========================================================================
    BEGIN
        CALL silver.validate_load();
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Validation execution encountered error: %', SQLERRM;
    END;

    -- =========================================================================
    -- STEP 5: Final Report Printing (FOR Loop Procedure)
    -- =========================================================================
    BEGIN
        CALL silver.print_load_summary(v_run_start_time);
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Report generation encountered error: %', SQLERRM;
    END;

END;
$$;
