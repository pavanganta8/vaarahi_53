-- =====================================================================
-- TOPIC: DYNAMIC TABLES IN SNOWFLAKE
-- =====================================================================
-- Explanation:
-- 1. Dynamic Tables are declarative. You specify the query, and Snowflake
--    manages the data pipeline, scheduling, and incremental refresh automatically.
-- 2. Instead of writing streams, tasks, and stored procedures, you define
--    what the target table should look like.
-- 3. You specify a 'TARGET_LAG', which is the maximum time the data can lag
--    behind the source tables.
-- =====================================================================

-- Step 1: Base table (source table containing real-time stream of events)
CREATE OR REPLACE TABLE student_notes.public.user_clicks (
    click_id INT,
    user_id INT,
    page_url VARCHAR(255),
    click_time TIMESTAMP
);

INSERT INTO student_notes.public.user_clicks VALUES
(1, 101, '/home', '2026-06-24 10:00:00'),
(2, 102, '/pricing', '2026-06-24 10:01:00');


-- Step 2: Create a Dynamic Table
-- Target lag specifies how fresh the dynamic table needs to be (e.g. 1 minute, 1 hour, or DOWNSTREAM).
CREATE OR REPLACE DYNAMIC TABLE student_notes.public.click_summary
  TARGET_LAG = '1 minute' -- Auto-refreshes data every 1 minute
  WAREHOUSE = COMPUTE_WH  -- Warehouse used to execute the refresh
  AS
    SELECT 
        page_url,
        COUNT(click_id) AS total_clicks,
        MAX(click_time) AS last_click_at
    FROM student_notes.public.user_clicks
    GROUP BY page_url;


-- Step 3: Query the Dynamic Table (displays current state)
SELECT * FROM student_notes.public.click_summary;


-- Step 4: Add new data to the source table
INSERT INTO student_notes.public.user_clicks VALUES
(3, 101, '/pricing', '2026-06-24 10:02:00'),
(4, 103, '/home', '2026-06-24 10:03:00');

-- The click_summary table will automatically reflect these updates after the lag duration passes.


-- Step 5: Force a manual refresh (ideal for testing or ad-hoc updates)
ALTER DYNAMIC TABLE student_notes.public.click_summary REFRESH;


-- Step 6: Monitor Refresh History
-- View the status, duration, and resources consumed by refreshes.
SELECT * 
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY(
    NAME_PREFIX => 'STUDENT_NOTES.PUBLIC.CLICK_SUMMARY'
))
ORDER BY REFRESH_VERSION DESC;
