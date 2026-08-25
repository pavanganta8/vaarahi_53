-- =========================================================================
-- TUTORIAL: Variables and Data Types in PL/pgSQL
-- DESCRIPTION: This file explains how to declare and use variables, constants,
--              anchored types (%TYPE), and different data types within a PL/pgSQL block.
-- USAGE: You can execute this anonymous code block in any PostgreSQL client (pgAdmin, psql, etc.)
-- =========================================================================

DO $$
DECLARE
    -- 1. Standard Data Types
    v_student_id   INTEGER := 101;                       -- Integer variable initialized with default value
    v_student_name VARCHAR(50) := 'John Doe';            -- Variable-length character string
    v_gpa          NUMERIC(3, 2) := 3.75;                -- Numeric type (precision=3, scale=2)
    v_is_active    BOOLEAN := TRUE;                      -- Boolean variable
    v_enroll_date  DATE := CURRENT_DATE;                 -- Date initialized with current system date

    -- 2. Constants (values that cannot be changed once initialized)
    c_max_gpa      CONSTANT NUMERIC(3,2) := 4.00;
    
    -- 3. Anchored Types (%TYPE)
    -- This inherits the data type dynamically from an existing table or column.
    -- (Assuming a table exists, but here we can reference another declared variable for demonstration)
    v_student_copy v_student_name%TYPE := 'Jane Smith';

    -- 4. Special types: RECORD (can hold a row structure)
    v_record       RECORD;

BEGIN
    -- Logging information to the console/message tab in PostgreSQL
    RAISE NOTICE '--- 1. Variable Declarations & Initialization ---';
    RAISE NOTICE 'Student ID: %', v_student_id;
    RAISE NOTICE 'Student Name: %', v_student_name;
    RAISE NOTICE 'GPA: % / % (Max GPA)', v_gpa, c_max_gpa;
    RAISE NOTICE 'Is Active: %', v_is_active;
    RAISE NOTICE 'Enrollment Date: %', v_enroll_date;
    
    -- Reassigning variables
    v_student_name := 'Johnathan Doe';
    v_gpa := 3.89;
    
    RAISE NOTICE '--- 2. Variable Reassignment ---';
    RAISE NOTICE 'Updated Student Name: %', v_student_name;
    RAISE NOTICE 'Updated GPA: %', v_gpa;

    -- Using Anchored Variable (%TYPE)
    RAISE NOTICE '--- 3. Anchored Type (%%TYPE) Example ---';
    RAISE NOTICE 'Copied Student Name Type Value: %', v_student_copy;

    -- Using RECORD variable with a dynamically created row
    RAISE NOTICE '--- 4. RECORD Type Example ---';
    FOR v_record IN SELECT 1 AS id, 'Math' AS subject, 'A' AS grade LOOP
        RAISE NOTICE 'Record ID: %, Subject: %, Grade: %', v_record.id, v_record.subject, v_record.grade;
    END LOOP;

END $$;
