-- =========================================================================
-- PROCEDURE: silver.validate_load
-- DESCRIPTION: Runs a loop over the silver tables to verify record counts.
--              Demonstrates the WHILE Loop control structure.
-- =========================================================================

CREATE OR REPLACE PROCEDURE silver.validate_load()
LANGUAGE plpgsql
AS $$
DECLARE
    v_check_index INTEGER := 1;
    v_check_table VARCHAR(100);
    v_check_count INTEGER;
BEGIN
    RAISE NOTICE '--- Post Load Verification checklist ---';
    
    WHILE v_check_index <= 3 LOOP
        -- Decide table to check based on loop index
        IF v_check_index = 1 THEN
            v_check_table := 'silver.dim_customer';
        ELSIF v_check_index = 2 THEN
            v_check_table := 'silver.dim_products';
        ELSE
            v_check_table := 'silver.fact_products_sales';
        END IF;
        
        -- Dynamic SQL execution to get count
        EXECUTE 'SELECT COUNT(*) FROM ' || v_check_table INTO v_check_count;
        
        IF v_check_count = 0 THEN
            RAISE WARNING 'Check Failed: % has 0 rows!', v_check_table;
        ELSE
            RAISE NOTICE 'Check Passed: % contains % records.', v_check_table, v_check_count;
        END IF;
        
        v_check_index := v_check_index + 1;
    END LOOP;
END;
$$;
