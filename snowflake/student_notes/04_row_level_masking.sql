-- =====================================================================
-- TOPIC: ROW-LEVEL SECURITY / ROW ACCESS POLICIES IN SNOWFLAKE
-- =====================================================================
-- Explanation:
-- 1. Row Access Policies determine which rows are returned in query results.
-- 2. Restricts row visibility based on the user's role, login name, or lookup maps.
-- 3. Enables multi-tenant configurations in the same physical table.
-- =====================================================================

-- Step 1: Create a table representing regional sales
CREATE OR REPLACE TABLE student_notes.public.regional_sales (
    sale_id INT,
    region VARCHAR(50),
    amount DECIMAL(10,2),
    sales_rep VARCHAR(50)
);

INSERT INTO student_notes.public.regional_sales VALUES
(1, 'NORTH_AMERICA', 50000.00, 'Alice'),
(2, 'EUROPE', 75000.00, 'Bob'),
(3, 'ASIA', 110000.00, 'Charlie'),
(4, 'NORTH_AMERICA', 23000.00, 'David');


-- Step 2: Create a Row Access Policy
-- Accountadmin can see all. Regional roles (e.g. NORTH_AMERICA_ROLE) can only see their region.
-- Others will see nothing or restricted rows.
CREATE OR REPLACE ROW ACCESS POLICY student_notes.public.sales_region_policy
AS (region_col VARCHAR) RETURNS BOOLEAN ->
  CURRENT_ROLE() = 'ACCOUNTADMIN'
  OR (CURRENT_ROLE() = 'NORTH_AMERICA_ROLE' AND region_col = 'NORTH_AMERICA')
  OR (CURRENT_ROLE() = 'EUROPE_ROLE' AND region_col = 'EUROPE')
  -- Alternatively, map users dynamically
  -- OR CURRENT_USER() = 'SYSTEM_USER'
;


-- Step 3: Apply the Row Access Policy to the table
ALTER TABLE student_notes.public.regional_sales
ADD ROW ACCESS POLICY student_notes.public.sales_region_policy ON (region);


-- Step 4: Test the Row Access Policy
-- As ACCOUNTADMIN, you see all 4 rows:
USE ROLE ACCOUNTADMIN;
SELECT * FROM student_notes.public.regional_sales;

-- If we mock a regional role (assuming the role exists or is created):
-- CREATE ROLE NORTH_AMERICA_ROLE;
-- GRANT SELECT ON TABLE student_notes.public.regional_sales TO ROLE NORTH_AMERICA_ROLE;
-- USE ROLE NORTH_AMERICA_ROLE;
-- SELECT * FROM student_notes.public.regional_sales; -- Will only return rows where region = 'NORTH_AMERICA'


-- Step 5: Remove / Drop Row Access Policy
USE ROLE ACCOUNTADMIN;

-- Remove policy from table
ALTER TABLE student_notes.public.regional_sales
DROP ROW ACCESS POLICY student_notes.public.sales_region_policy;

-- Delete the policy object
DROP ROW ACCESS POLICY student_notes.public.sales_region_policy;
