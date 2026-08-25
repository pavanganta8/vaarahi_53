-- =========================================================================
-- TUTORIAL: Advanced Exception Handling in PL/pgSQL
-- DESCRIPTION: This file demonstrates nested blocks, raising user-defined 
--              exceptions, and utilizing custom SQLSTATEs, Details, and Hints.
-- USAGE: Execute the anonymous block in your PostgreSQL query tool.
-- =========================================================================

DO $$
DECLARE
    v_age INTEGER := 16; -- Assume age limit for a course is 18
BEGIN
    RAISE NOTICE '--- 1. Raising User-Defined Exceptions ---';
    
    -- Check custom validation condition
    IF v_age < 18 THEN
        -- Raise exception with custom error code, message, detail, and hint
        RAISE EXCEPTION 'Student is underage for this course'
            USING ERRCODE = 'invalid_parameter_value', -- Maps to pre-defined or custom error codes
                  DETAIL = 'Age provided: ' || v_age || '. Minimum required age: 18.',
                  HINT = 'Please enroll the student in a junior level course instead.';
    END IF;

EXCEPTION
    WHEN invalid_parameter_value THEN
        RAISE WARNING 'Caught Custom Exception!';
        RAISE NOTICE 'Message: %', SQLERRM;
        
        -- We can obtain extended error details using GET STACKED DIAGNOSTICS
        DECLARE
            v_err_msg    TEXT;
            v_err_detail TEXT;
            v_err_hint   TEXT;
        BEGIN
            GET STACKED DIAGNOSTICS 
                v_err_msg = MESSAGE_TEXT,
                v_err_detail = PG_EXCEPTION_DETAIL,
                v_err_hint = PG_EXCEPTION_HINT;
                
            RAISE NOTICE 'Detail from Diagnostics: %', v_err_detail;
            RAISE NOTICE 'Hint from Diagnostics: %', v_err_hint;
        END;
END $$;


-- -------------------------------------------------------------------------
-- Example 2: Nested Block Exception Handling (Isolating Errors)
-- -------------------------------------------------------------------------
DO $$
BEGIN
    RAISE NOTICE '--- 2. Nested Blocks and Isolation ---';
    
    -- Main block starts
    BEGIN
        -- Nested block A: Might fail, but we want the main block to continue
        BEGIN
            RAISE NOTICE 'Starting Nested Block A...';
            -- Intentional error: division by zero
            PERFORM 10 / 0;
        EXCEPTION
            WHEN division_by_zero THEN
                RAISE NOTICE 'Nested Block A failed, but error was caught and handled locally.';
        END;
        
        -- Nested block B: Runs successfully because Block A's failure was caught
        BEGIN
            RAISE NOTICE 'Starting Nested Block B...';
            RAISE NOTICE 'Nested Block B executed successfully.';
        END;
        
        RAISE NOTICE 'Main block logic continues safely!';
    END;
END $$;
