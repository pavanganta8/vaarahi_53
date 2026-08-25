-- =====================================================================
-- TOPIC: MICRO-PARTITIONING & CLUSTERING IN SNOWFLAKE
-- =====================================================================
-- Explanation:
-- 1. Snowflake automatically manages partitioning via "Micro-partitions".
-- 2. You do NOT define partitions manually like in traditional databases.
-- 3. For very large tables (TB scale), you can define a "Clustering Key"
--    to optimize query pruning and performance.
-- =====================================================================

-- Step 1: Create a table with a Clustering Key
CREATE OR REPLACE TABLE student_notes.public.sales_data (
    sales_id INT,
    customer_id INT,
    product_category VARCHAR(50),
    sales_amount DECIMAL(10,2),
    transaction_date DATE
)
CLUSTER BY (transaction_date, product_category); -- Defines the clustering key


-- Step 2: Load sample data (automatic partitioning happens here)
INSERT INTO student_notes.public.sales_data VALUES
(1, 101, 'Electronics', 1500.00, '2026-01-01'),
(2, 102, 'Clothing', 45.50, '2026-01-01'),
(3, 103, 'Electronics', 800.00, '2026-01-02'),
(4, 104, 'Home Decor', 120.00, '2026-01-02'),
(5, 105, 'Clothing', 99.99, '2026-01-03');


-- Step 3: Check clustering depth & details
-- Depth = 1 is ideal. Higher numbers indicate less optimal clustering.
SELECT SYSTEM$CLUSTERING_DEPTH('student_notes.public.sales_data');

-- Detailed clustering information
SELECT SYSTEM$CLUSTERING_INFORMATION('student_notes.public.sales_data');


-- Step 4: Modifying the clustering key of an existing table
ALTER TABLE student_notes.public.sales_data CLUSTER BY (product_category);


-- Step 5: Suspend/Resume Automatic Clustering
-- (Automatic clustering incurs credit costs, you can manage it)
ALTER TABLE student_notes.public.sales_data SUSPEND RECLUSTER;
ALTER TABLE student_notes.public.sales_data RESUME RECLUSTER;


-- Step 6: Query optimization using clustering key (Pruning demonstration)
-- The query engine will prune partitions and only read necessary ones.
SELECT * 
FROM student_notes.public.sales_data
WHERE transaction_date = '2026-01-01' 
  AND product_category = 'Electronics';
