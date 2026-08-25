-- =========================================================================
-- TUTORIAL: Cursors in PL/pgSQL
-- DESCRIPTION: This file explains how to declare, open, fetch from, close, 
--              and loop through cursors in PL/pgSQL.
-- USAGE: Execute the anonymous block in your PostgreSQL query tool.
-- =========================================================================

DO $$
DECLARE
    -- 1. Declare an unbound cursor
    c_student_cursor REFCURSOR;
    
    -- Variables to hold fetched data
    v_name VARCHAR(50);
    v_dept VARCHAR(50);

    -- 2. Declare a bound cursor with a parameter
    -- This cursor selects courses based on the department parameter passed to it
    c_course_cursor CURSOR(p_department VARCHAR) FOR
        SELECT course_name, credit_hours 
        FROM (
            SELECT 'Database Systems' AS course_name, 4 AS credit_hours, 'CS' AS dept
            UNION ALL
            SELECT 'Algorithms' AS course_name, 3 AS credit_hours, 'CS' AS dept
            UNION ALL
            SELECT 'Thermodynamics' AS course_name, 4 AS credit_hours, 'ME' AS dept
        ) AS mock_courses
        WHERE dept = p_department;
        
    v_course_name VARCHAR(50);
    v_credits     INTEGER;
BEGIN
    RAISE NOTICE '--- 1. Manual Cursor Management (Open, Fetch, Close) ---';
    
    -- Open the unbound cursor for a dynamic query
    OPEN c_student_cursor FOR 
        SELECT 'Alice' AS name, 'Physics' AS dept
        UNION ALL
        SELECT 'Bob' AS name, 'Chemistry' AS dept;
        
    LOOP
        -- Fetch next row into variables
        FETCH c_student_cursor INTO v_name, v_dept;
        
        -- Exit loop when no more rows are found
        EXIT WHEN NOT FOUND;
        
        RAISE NOTICE 'Student: %, Department: %', v_name, v_dept;
    END LOOP;
    
    -- Close the cursor to free resources
    CLOSE c_student_cursor;

    RAISE NOTICE '--- 2. Bound Cursor with Parameters ---';
    
    -- Open cursor by passing the argument 'CS' for p_department
    OPEN c_course_cursor(p_department := 'CS');
    
    LOOP
        FETCH c_course_cursor INTO v_course_name, v_credits;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Course: %, Credits: %', v_course_name, v_credits;
    END LOOP;
    
    CLOSE c_course_cursor;

    RAISE NOTICE '--- 3. Cursor FOR Loop (Automatic Management) ---';
    -- A Cursor FOR loop is highly recommended because PostgreSQL automatically 
    -- opens the cursor, fetches rows, and closes the cursor when the loop ends.
    FOR r_course IN c_course_cursor('ME') LOOP
        RAISE NOTICE 'Auto-managed Course: %, Credits: %', r_course.course_name, r_course.credit_hours;
    END LOOP;

END $$;
