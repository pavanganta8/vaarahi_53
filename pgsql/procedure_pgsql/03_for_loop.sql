-- =========================================================================
-- TUTORIAL: FOR Loops in PL/pgSQL
-- DESCRIPTION: This file demonstrates various ways to use FOR loops in PL/pgSQL,
--              including loops through ranges (with step increments and reverse order)
--              and looping through query result sets.
-- USAGE: Execute the anonymous block in your PostgreSQL query tool.
-- =========================================================================

DO $$
DECLARE
    v_counter INTEGER;
    -- A RECORD variable to hold dynamic rows fetched from a query loop
    v_row     RECORD;
BEGIN
    RAISE NOTICE '--- 1. Simple FOR Loop (1 to 5) ---';
    -- The loop variable 'i' is automatically declared as integer inside the loop
    FOR i IN 1..5 LOOP
        RAISE NOTICE 'Iteration: %', i;
    END LOOP;

    RAISE NOTICE '--- 2. Reverse FOR Loop (5 down to 1) ---';
    -- Loops backwards from 5 to 1 using REVERSE keyword
    FOR i IN REVERSE 5..1 LOOP
        RAISE NOTICE 'Reverse Iteration: %', i;
    END LOOP;

    RAISE NOTICE '--- 3. FOR Loop with Step Increment (BY 2) ---';
    -- Loops from 1 to 10 incrementing by 2 at each step
    FOR i IN 1..10 BY 2 LOOP
        RAISE NOTICE 'Step Iteration (BY 2): %', i;
    END LOOP;

    RAISE NOTICE '--- 4. FOR Loop with LOOP control (EXIT/CONTINUE) ---';
    -- Loop 1 to 10 but skip 5, and terminate loop at 8
    FOR i IN 1..10 LOOP
        IF i = 5 THEN
            RAISE NOTICE 'Skipping number % using CONTINUE', i;
            CONTINUE; -- Skips the rest of the current loop iteration
        END IF;
        
        IF i = 8 THEN
            RAISE NOTICE 'Exiting loop at % using EXIT', i;
            EXIT; -- Terminates the loop completely
        END IF;
        
        RAISE NOTICE 'Processing number: %', i;
    END LOOP;

    RAISE NOTICE '--- 5. FOR Loop Over Query Results ---';
    -- In this loop, we query standard system columns or dynamic values.
    -- v_row gets populated with each row returned by the SELECT query.
    FOR v_row IN (
        SELECT 'Mathematics' AS course_name, 30 AS students_enrolled
        UNION ALL
        SELECT 'Computer Science', 45
        UNION ALL
        SELECT 'Physics', 25
    ) LOOP
        RAISE NOTICE 'Course: %, Enrolled: % students', v_row.course_name, v_row.students_enrolled;
    END LOOP;

END $$;
