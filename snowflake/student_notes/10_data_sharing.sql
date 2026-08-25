-- =====================================================================
-- TOPIC: SECURE DATA SHARING IN SNOWFLAKE
-- =====================================================================
-- Explanation:
-- 1. Data Sharing enables sharing tables/views with other Snowflake accounts
--    instantly without physically copying or moving data.
-- 2. Shared data is read-only.
-- 3. Providers pay for storage; Consumers pay for compute query resources.
-- 4. To protect internal query logic or table schemas, use SECURE VIEWS.
-- =====================================================================

-- =====================================================================
-- PROVIDER ACCOUNT SIDE STEPS:
-- =====================================================================

-- Step 1: Create a Secure View (highly recommended to hide source DDL details)
CREATE OR REPLACE SECURE VIEW student_notes.public.secure_partner_sales AS
SELECT 
    sale_id,
    region,
    amount
FROM student_notes.public.regional_sales
WHERE region IN ('NORTH_AMERICA', 'EUROPE');


-- Step 2: Create a Share Container
USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE SHARE student_sales_share;


-- Step 3: Grant usage privileges on DB, Schema, and View/Table to the share
GRANT USAGE ON DATABASE student_notes TO SHARE student_sales_share;
GRANT USAGE ON SCHEMA student_notes.public TO SHARE student_sales_share;
GRANT SELECT ON VIEW student_notes.public.secure_partner_sales TO SHARE student_sales_share;


-- Step 4: Add consumer accounts to the share
-- Replace 'XY12345' with the target Snowflake account locator.
-- ALTER SHARE student_sales_share ADD ACCOUNTS = XY12345;


-- =====================================================================
-- CONSUMER ACCOUNT SIDE STEPS:
-- =====================================================================

-- Step 1: View incoming shares (shows shares available to your account)
-- SHOW SHARES;

-- Step 2: Create a local database from the provider's share
-- Replace 'PROVIDER_ACCOUNT' with the provider account name.
-- CREATE OR REPLACE DATABASE consumer_sales_db 
-- FROM SHARE PROVIDER_ACCOUNT.student_sales_share;

-- Step 3: Query the shared data (instant access!)
-- SELECT * FROM consumer_sales_db.public.secure_partner_sales;
