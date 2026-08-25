-- =====================================================================
-- TOPIC: COLUMN-LEVEL DYNAMIC DATA MASKING IN SNOWFLAKE
-- =====================================================================
-- Explanation:
-- 1. Dynamic Data Masking allows you to apply a masking policy to a column.
-- 2. Sensitive data is masked on-the-fly at query time based on user roles.
-- 3. The raw data remains unmasked on disk (safe and secure).
-- =====================================================================

-- Step 1: Create a table containing sensitive information
CREATE OR REPLACE TABLE student_notes.public.customer_pii (
    cust_id INT,
    first_name VARCHAR(50),
    email_address VARCHAR(100),
    credit_card VARCHAR(20)
);

INSERT INTO student_notes.public.customer_pii VALUES
(1001, 'John', 'john.doe@gmail.com', '1234-5678-9012-3456'),
(1002, 'Sarah', 'sarah.smith@yahoo.com', '9876-5432-1098-7654');


-- Step 2: Create a Masking Policy
-- Only roles listed (e.g., 'ACCOUNTADMIN', 'HR_ADMIN') see raw data. Others see masked values.
CREATE OR REPLACE MASKING POLICY student_notes.public.email_mask AS (val string) 
RETURNS string ->
  CASE
    WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SECURITYADMIN') THEN val
    ELSE REGEXP_REPLACE(val, '(?<=.)[^@](?=[^@]*?[^@].)', '*') -- Mask email body: j***n@gmail.com
  END;

CREATE OR REPLACE MASKING POLICY student_notes.public.cc_mask AS (val string) 
RETURNS string ->
  CASE
    WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN') THEN val
    ELSE 'XXXX-XXXX-XXXX-' || RIGHT(val, 4) -- Mask CC to show only last 4 digits
  END;


-- Step 3: Apply the Masking Policies to the table columns
ALTER TABLE student_notes.public.customer_pii 
MODIFY COLUMN email_address SET MASKING POLICY student_notes.public.email_mask;

ALTER TABLE student_notes.public.customer_pii 
MODIFY COLUMN credit_card SET MASKING POLICY student_notes.public.cc_mask;


-- Step 4: Test the data masking with different roles
-- If you are ACCOUNTADMIN, you see full info:
USE ROLE ACCOUNTADMIN;
SELECT * FROM student_notes.public.customer_pii;

-- If you switch to a lower role, the data is automatically masked:
USE ROLE PUBLIC;
SELECT * FROM student_notes.public.customer_pii;


-- Step 5: Unset / Remove Masking Policy
USE ROLE ACCOUNTADMIN;

ALTER TABLE student_notes.public.customer_pii 
MODIFY COLUMN email_address UNSET MASKING POLICY;

ALTER TABLE student_notes.public.customer_pii 
MODIFY COLUMN credit_card UNSET MASKING POLICY;

DROP MASKING POLICY student_notes.public.email_mask;
DROP MASKING POLICY student_notes.public.cc_mask;
