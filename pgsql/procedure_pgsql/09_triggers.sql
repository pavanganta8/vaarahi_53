-- =========================================================================
-- TUTORIAL: Triggers in PostgreSQL
-- DESCRIPTION: This file demonstrates how to create trigger functions and
--              bind them to tables for automatic execution during INSERT/UPDATE operations.
-- USAGE: Run this script sequentially to create the tables, trigger function,
--        trigger, and then test the behavior with updates.
-- =========================================================================

-- 1. PREPARATION: Create a sample table and an audit log table
DROP TABLE IF EXISTS student_logs;
DROP TABLE IF EXISTS students_table;

CREATE TABLE students_table (
    student_id SERIAL PRIMARY KEY,
    student_name VARCHAR(100) NOT NULL,
    score NUMERIC(5, 2)
);

CREATE TABLE student_logs (
    log_id SERIAL PRIMARY KEY,
    student_id INT,
    action_performed VARCHAR(50),
    old_score NUMERIC(5, 2),
    new_score NUMERIC(5, 2),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- 2. TRIGGER FUNCTION: Must return type "TRIGGER"
-- In PostgreSQL, triggers run a special function that has access to special
-- variables: NEW (new row state), OLD (old row state), TG_OP (trigger operation: INSERT, UPDATE, etc.)
CREATE OR REPLACE FUNCTION audit_student_score_changes()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if it is an UPDATE operation
    IF TG_OP = 'UPDATE' THEN
        -- Only log if the score actually changed
        IF OLD.score IS DISTINCT FROM NEW.score THEN
            INSERT INTO student_logs(student_id, action_performed, old_score, new_score)
            VALUES (OLD.student_id, 'UPDATE_SCORE', OLD.score, NEW.score);
        END IF;
        
    -- Check if it is an INSERT operation
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO student_logs(student_id, action_performed, old_score, new_score)
        VALUES (NEW.student_id, 'INSERT_STUDENT', NULL, NEW.score);
        
    -- Check if it is a DELETE operation
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO student_logs(student_id, action_performed, old_score, new_score)
        VALUES (OLD.student_id, 'DELETE_STUDENT', OLD.score, NULL);
    END IF;

    -- For row-level triggers:
    -- BEFORE triggers should return NEW (or NULL to skip row operation)
    -- AFTER triggers can just return NULL/NEW (return value is ignored for AFTER triggers)
    RETURN NEW; 
END;
$$;


-- 3. BIND THE TRIGGER TO THE TABLE
-- This binds the trigger function to run AFTER any INSERT, UPDATE, or DELETE on students_table.
CREATE TRIGGER trg_student_score_audit
AFTER INSERT OR UPDATE OR DELETE
ON students_table
FOR EACH ROW
EXECUTE FUNCTION audit_student_score_changes();


-- 4. TESTING THE TRIGGER BEHAVIOR
RAISE NOTICE '--- Testing Triggers ---';

-- Insert a new student (This triggers the INSERT branch)
INSERT INTO students_table (student_name, score) VALUES ('Alice Smith', 85.0);
INSERT INTO students_table (student_name, score) VALUES ('Bob Jones', 72.5);

-- Check tables to see if audit log was written automatically
SELECT * FROM students_table;
SELECT * FROM student_logs;

-- Update a student's score (This triggers the UPDATE branch)
UPDATE students_table SET score = 90.0 WHERE student_name = 'Alice Smith';

-- Check tables again
SELECT * FROM students_table;
SELECT * FROM student_logs;

-- Delete a student (This triggers the DELETE branch)
DELETE FROM students_table WHERE student_name = 'Bob Jones';

-- Final check of logs
SELECT * FROM student_logs;
