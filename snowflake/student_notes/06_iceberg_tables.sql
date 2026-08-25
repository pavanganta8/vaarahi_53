-- =====================================================================
-- TOPIC: APACHE ICEBERG TABLES IN SNOWFLAKE
-- =====================================================================
-- Explanation:
-- 1. Iceberg tables use the open Apache Iceberg specification.
-- 2. Data is stored in customer-managed cloud storage (S3, Azure Blob, GCS) in Parquet format.
-- 3. Snowflake can either MANAGE the catalog (read/write) or use an EXTERNAL catalog
--    like AWS Glue, REST Catalog, or Hive (read-only or sync).
-- 4. Requires an "External Volume" to establish secure storage credentials.
-- =====================================================================

-- Step 1: Create an External Volume (points to S3, GCS, or Azure Blob)
-- (Note: Storage integration/credentials must be set up beforehand)
CREATE OR REPLACE EXTERNAL VOLUME iceberg_external_vol
   STORAGE_LOCATIONS = (
      (
         NAME = 'my-s3-us-east-1'
         STORAGE_PROVIDER = 'S3'
         STORAGE_BASE_URL = 's3://my-iceberg-bucket/data/'
         STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::123456789012:role/my-snowflake-role'
      )
   );


-- Step 2: Create an Iceberg Table Managed by Snowflake
-- Snowflake manages the metadata, writes parquet files to external volume.
CREATE OR REPLACE ICEBERG TABLE student_notes.public.iceberg_customers (
    customer_id INT,
    customer_name VARCHAR(100),
    signup_date DATE
)
CATALOG = 'SNOWFLAKE'
EXTERNAL_VOLUME = 'iceberg_external_vol'
BASE_LOCATION = 'customers_table/';


-- Step 3: Insert and Query data in a Snowflake-managed Iceberg Table
INSERT INTO student_notes.public.iceberg_customers VALUES 
(1, 'TechCorp', '2026-02-15'),
(2, 'DesignStudio', '2026-03-01');

SELECT * FROM student_notes.public.iceberg_customers;


-- Step 4: Create an Iceberg Table using an External Catalog (e.g., AWS Glue)
-- Useful when other query engines (Spark, Trino) write to the Iceberg table.

-- Create the Catalog Integration first
CREATE OR REPLACE CATALOG INTEGRATION glue_catalog_int
  CATALOG_SOURCE = 'GLUE'
  CATALOG_NAMESPACE = 'my_glue_db'
  TABLE_FORMAT = 'ICEBERG'
  GLUE_AWS_ROLE_ARN = 'arn:aws:iam::123456789012:role/my-glue-role'
  GLUE_CATALOG_ID = '123456789012';

-- Create the table referencing Glue
CREATE OR REPLACE ICEBERG TABLE student_notes.public.iceberg_glue_sales
  EXTERNAL_VOLUME = 'iceberg_external_vol'
  CATALOG = 'glue_catalog_int'
  CATALOG_TABLE_NAME = 'glue_sales_table';
