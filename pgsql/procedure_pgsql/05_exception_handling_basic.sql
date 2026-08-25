-- =========================================================================
-- TUTORIAL: Basic Exception Handling in PL/pgSQL
-- DESCRIPTION: This file demonstrates how to catch runtime errors (exceptions)
--              using the EXCEPTION block, preventing the transaction from failing.
-- USAGE: Execute the anonymous block in your PostgreSQL query tool.
-- =========================================================================

DO $$
DECLARE
    v_numerator   INTEGER := 10;
    v_denominator INTEGER := 0; -- Will cause division by zero error
    v_result      INTEGER;
BEGIN
    RAISE NOTICE '--- 1. Attempting division by zero ---';
    
    -- The following statement raises a DIVISION_BY_ZERO exception
    v_result := v_numerator / v_denominator;
    
    -- This line will not be executed because execution jumps directly to the EXCEPTION block
    RAISE NOTICE 'Result: %', v_result;

EXCEPTION
    -- Catch division by zero specifically
    WHEN division_by_zero THEN
        RAISE WARNING 'An error occurred: Cannot divide by zero!';
        v_result := 0; -- Provide a fallback/default value
        RAISE NOTICE 'Handled exception. Assigned fallback result: %', v_result;
        
    -- Catch all other types of errors
    WHEN OTHERS THEN
        RAISE NOTICE 'An unexpected error occurred.';
END $$;


-- -------------------------------------------------------------------------
-- Example 2: Accessing system error messages (SQLSTATE and SQLERRM)
-- -------------------------------------------------------------------------
DO $$
DECLARE
    v_number INTEGER;
BEGIN
    RAISE NOTICE '--- 2. Retrieving Error Details ---';
    
    -- Attempting to assign a non-numeric string to an integer variable
    v_number := 'NotANumber'::INTEGER;

EXCEPTION
    WHEN OTHERS THEN
        -- SQLSTATE represents the error code, SQLERRM is the error message string
        RAISE WARNING 'Error Code (SQLSTATE): %', SQLSTATE;
        RAISE WARNING 'Error Message (SQLERRM): %', SQLERRM;
END $$;
