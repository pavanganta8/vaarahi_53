-- =====================================================================
-- TOPIC: HYBRID TABLES (UNISTORE) IN SNOWFLAKE
-- =====================================================================
-- Explanation:
-- 1. Hybrid Tables support fast transactional (OLTP) and analytical (OLAP) workloads.
-- 2. They offer low latency, single-row lookups, and operational read/writes.
-- 3. Primary Key constraints are ENFORCED (unlike standard tables where they are informational).
-- 4. Foreign Keys and Unique constraints are also enforced.
-- =====================================================================

-- Step 1: Create a Hybrid Table
-- Note: Hybrid Tables require a Primary Key and run on specific cloud infrastructures.
CREATE OR REPLACE HYBRID TABLE student_notes.public.user_accounts (
    user_id INT PRIMARY KEY,
    user_email VARCHAR(100) UNIQUE,
    user_status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);


-- Step 2: Insert data (enforces primary key & unique index checks immediately)
INSERT INTO student_notes.public.user_accounts (user_id, user_email, user_status)
VALUES 
(1, 'alice@company.com', 'ACTIVE'),
(2, 'bob@company.com', 'PENDING');

-- Step 3: Test PK enforcement (This query will fail due to duplicate primary key)
-- INSERT INTO student_notes.public.user_accounts (user_id, user_email) 
-- VALUES (1, 'duplicate@company.com'); 


-- Step 4: Test Unique constraint enforcement (This will also fail)
-- INSERT INTO student_notes.public.user_accounts (user_id, user_email) 
-- VALUES (3, 'alice@company.com'); 


-- Step 5: Fast single-row updates (OLTP style)
UPDATE student_notes.public.user_accounts
SET user_status = 'ACTIVE'
WHERE user_id = 2;


-- Step 6: Querying hybrid tables
-- You can join hybrid tables with standard/analytical tables seamlessly
SELECT * 
FROM student_notes.public.user_accounts 
WHERE user_id = 1;
