-- =====================================================================
-- TOPIC: EXTERNAL TABLES IN SNOWFLAKE
-- =====================================================================
-- Explanation:
-- 1. External Tables let you query data stored in external stages (S3, Blob, GCS)
--    without loading the data into Snowflake storage.
-- 2. Data is read-only. Useful for archives, ad-hoc queries, or staging layers.
-- 3. They store a metadata cache of files, which can be auto-refreshed.
-- =====================================================================

-- Step 1: Create an External Stage pointing to cloud storage
CREATE OR REPLACE STAGE student_notes.public.ext_s3_stage
  URL = 's3://my-company-raw-data-bucket/logs/'
  -- STORAGE_INTEGRATION = my_s3_integration -- Set up beforehand
;


-- Step 2: Create a File Format (e.g., CSV or JSON or Parquet)
CREATE OR REPLACE FILE FORMAT student_notes.public.json_format
  TYPE = 'JSON'
  STRIP_OUTER_ARRAY = TRUE;


-- Step 3: Create an External Table
-- The 'VALUE' column is a variant column containing the entire file row structure.
-- We define expressions on VALUE to construct virtual columns.
CREATE OR REPLACE EXTERNAL TABLE student_notes.public.ext_server_logs (
    log_id VARCHAR(64) AS (value:log_id::VARCHAR),
    log_level VARCHAR(10) AS (value:log_level::VARCHAR),
    log_timestamp TIMESTAMP AS (value:timestamp::TIMESTAMP),
    message VARCHAR(500) AS (value:message::VARCHAR)
)
WITH LOCATION = @student_notes.public.ext_s3_stage
FILE_FORMAT = (FORMAT_NAME = 'student_notes.public.json_format');


-- Step 4: Query the External Table
SELECT log_id, log_level, log_timestamp, message 
FROM student_notes.public.ext_server_logs
WHERE log_level = 'ERROR';


-- Step 5: Partitioned External Table
-- Pruning performance increases when external tables are partitioned.
-- We can partition by dates extracted from the file paths.
CREATE OR REPLACE EXTERNAL TABLE student_notes.public.ext_partitioned_logs (
    log_date DATE AS (TO_DATE(SPLIT_PART(metadata$filename, '/', 2), 'YYYY-MM-DD')),
    log_level VARCHAR(10) AS (value:log_level::VARCHAR)
)
PARTITION BY (log_date)
LOCATION = @student_notes.public.ext_s3_stage
FILE_FORMAT = (TYPE = 'JSON');


-- Step 6: Manually Refresh External Table Metadata
-- Required if new files are added to S3 and auto-refresh is not configured.
ALTER EXTERNAL TABLE student_notes.public.ext_server_logs REFRESH;
