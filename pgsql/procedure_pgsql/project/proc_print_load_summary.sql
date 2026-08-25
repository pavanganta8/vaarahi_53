-- =========================================================================
-- PROCEDURE: silver.print_load_summary
-- DESCRIPTION: Iterates over load logs created during the execution run.
--              Demonstrates the FOR Loop control structure.
-- =========================================================================

CREATE OR REPLACE PROCEDURE silver.print_load_summary(
    p_run_start_time TIMESTAMP
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_log_record RECORD;
BEGIN
    RAISE NOTICE '==================================================';
    RAISE NOTICE 'ETL COMPLETED. CURRENT PIPELINE EXECUTION SUMMARY:';
    RAISE NOTICE '==================================================';
    
    FOR v_log_record IN (
        SELECT step_name, status, records_loaded, error_message 
        FROM audit.load_logs 
        WHERE logged_at >= p_run_start_time
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
