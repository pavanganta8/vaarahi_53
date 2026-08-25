-- =========================================================================
-- TUTORIAL: Functions in PostgreSQL (PL/pgSQL)
-- DESCRIPTION: This file demonstrates how to create and execute user-defined
--              functions (UDFs). It covers scalar functions, functions with IN/OUT
--              parameters, and table-returning functions.
-- USAGE: Run the SQL script to create the functions, then execute the test queries.
-- =========================================================================

-- -------------------------------------------------------------------------
-- Example 1: Basic Scalar Function
-- Calculates the final grade based on theory and lab scores.
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_final_score(
    p_theory_score NUMERIC,
    p_lab_score NUMERIC
) 
RETURNS NUMERIC 
LANGUAGE plpgsql
AS $$
DECLARE
    v_final_score NUMERIC;
BEGIN
    -- Validation: input cannot be negative
    IF p_theory_score < 0 OR p_lab_score < 0 THEN
        RAISE EXCEPTION 'Scores cannot be negative';
    END IF;
    
    -- Theory carries 60% weight, Lab carries 40% weight
    v_final_score := (p_theory_score * 0.60) + (p_lab_score * 0.40);
    
    RETURN v_final_score;
END;
$$;

-- Testing Example 1:
SELECT calculate_final_score(80, 90) AS calculated_score;


-- -------------------------------------------------------------------------
-- Example 2: Function with IN, OUT, and INOUT Parameters
-- Demonstrates how to return multiple values from a function.
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_student_stats(
    p_student_id IN INTEGER,
    p_name OUT VARCHAR,
    p_status OUT VARCHAR,
    p_gpa INOUT NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Set OUT parameters based on some dummy logic (or a real table select)
    IF p_student_id = 1 THEN
        p_name := 'Alice Vance';
        p_status := 'Active';
        -- Modify INOUT parameter
        p_gpa := p_gpa + 0.2; -- Add bonus GPA
    ELSE
        p_name := 'Unknown Student';
        p_status := 'Inactive';
    END IF;
END;
$$;

-- Testing Example 2:
-- Calling functions with OUT parameters returns a record structure
SELECT * FROM get_student_stats(1, 3.5);


-- -------------------------------------------------------------------------
-- Example 3: Function Returning a Table (RETURNS TABLE)
-- Useful for filtering and returning multiple records.
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_high_performers(p_min_grade NUMERIC)
RETURNS TABLE (
    student_id INT,
    student_name VARCHAR,
    grade NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- RETURN QUERY allows returning rows directly from a query
    RETURN QUERY
    SELECT * FROM (
        SELECT 101 AS s_id, CAST('Alice' AS VARCHAR) AS s_name, 95.5 AS s_grade
        UNION ALL
        SELECT 102 AS s_id, CAST('Bob' AS VARCHAR) AS s_name, 88.0 AS s_grade
        UNION ALL
        SELECT 103 AS s_id, CAST('Charlie' AS VARCHAR) AS s_name, 72.0 AS s_grade
    ) AS dummy_students
    WHERE s_grade >= p_min_grade;
END;
$$;

-- Testing Example 3:
SELECT * FROM get_high_performers(85.0);


-- -------------------------------------------------------------------------
-- Clean up (Optional commands to drop the functions)
-- -------------------------------------------------------------------------
-- DROP FUNCTION calculate_final_score(NUMERIC, NUMERIC);
-- DROP FUNCTION get_student_stats(INTEGER, NUMERIC);
-- DROP FUNCTION get_high_performers(NUMERIC);
