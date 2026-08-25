-- =====================================================================
-- TOPIC: TIME TRAVEL & FAIL-SAFE IN SNOWFLAKE
-- =====================================================================
-- Explanation:
-- 1. Time Travel enables accessing historical data (up to 90 days for Enterprise+).
-- 2. Uses include querying old data, restoring dropped tables/dbs, and backing up.
-- 3. Fail-safe provides 7 days of non-configurable storage after Time Travel expires.
-- =====================================================================

-- Step 1: Create table with Time Travel retention period (e.g., 5 days)
CREATE OR REPLACE TABLE student_notes.public.employee_data (
    emp_id INT,
    emp_name VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10,2)
)
DATA_RETENTION_TIME_IN_DAYS = 5; -- Set retention to 5 days (Standard is 1, Enterprise max 90)


-- Step 2: Insert initial data
INSERT INTO student_notes.public.employee_data VALUES 
(1, 'Alice', 'Engineering', 120000.00),
(2, 'Bob', 'HR', 80000.00);

-- Save current timestamp or query ID for later use
SET ts_before_update = CURRENT_TIMESTAMP();
-- Show current time for references
SELECT CURRENT_TIMESTAMP();


-- Step 3: Modify the data
UPDATE student_notes.public.employee_data
SET salary = 130000.00
WHERE emp_id = 1;

-- Save the update query ID (retrieve from query history)
SET query_id_update = LAST_QUERY_ID();


-- Step 4: Querying historical data
-- Method A: Querying data AT a specific timestamp
SELECT * 
FROM student_notes.public.employee_data 
AT(TIMESTAMP => $ts_before_update);

-- Method B: Querying data BEFORE a specific query execution
SELECT * 
FROM student_notes.public.employee_data 
BEFORE(STATEMENT => $query_id_update);

-- Method C: Querying data with an OFFSET (e.g., 5 minutes ago)
SELECT * 
FROM student_notes.public.employee_data 
AT(OFFSET => -300); -- -300 seconds (5 minutes)


-- Step 5: Restoring a table using Time Travel (UNDROP)
-- Drop the table
DROP TABLE student_notes.public.employee_data;

-- Attempting to query fails
-- SELECT * FROM student_notes.public.employee_data;

-- Restore it!
UNDROP TABLE student_notes.public.employee_data;

-- Confirm data is restored
SELECT * FROM student_notes.public.employee_data;


-- Step 6: Clone a table as of a specific point in time (Zero-Copy Clone)
CREATE OR REPLACE TABLE student_notes.public.employee_data_backup
CLONE student_notes.public.employee_data
AT(TIMESTAMP => $ts_before_update);
