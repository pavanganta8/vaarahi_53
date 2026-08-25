-- =========================================================================
-- PROJECT FILE: 01_ddl.sql
-- DESCRIPTION: Sets up the database schemas (bronze, silver, audit) and
--              creates the 6 required project tables and an audit logging table.
-- SCHEMAS:
--   - bronze: Holds raw, dirty, landing data from source systems.
--   - silver: Holds cleaned, validated, and structured dimensional models.
--   - audit: Holds logs for procedure execution and record audit trails.
-- =========================================================================

-- Create schemas if they do not exist
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS audit;

-- ==========================================
-- 1. BRONZE SCHEMA TABLES (Raw ingestion)
-- ==========================================

DROP TABLE IF EXISTS bronze.customer CASCADE;
CREATE TABLE bronze.customer (
    cust_id      VARCHAR(50),  -- deliberately varchar to simulate raw text
    cust_name    VARCHAR(150),
    email        VARCHAR(150),
    gender       VARCHAR(20),
    created_date VARCHAR(50)   -- raw format e.g. '19-06-2026' or '2026/06/19'
);

DROP TABLE IF EXISTS bronze.products CASCADE;
CREATE TABLE bronze.products (
    prod_id   VARCHAR(50),
    prod_name VARCHAR(150),
    category  VARCHAR(100),
    price     VARCHAR(50)      -- raw format with potential symbols e.g. '$120.50'
);

DROP TABLE IF EXISTS bronze.sales CASCADE;
CREATE TABLE bronze.sales (
    sale_id   VARCHAR(50),
    cust_id   VARCHAR(50),
    prod_id   VARCHAR(50),
    qty       VARCHAR(50),     -- varchar to allow handling raw data types
    sale_date VARCHAR(50)
);

-- ==========================================
-- 2. SILVER SCHEMA TABLES (Cleaned & Curated)
-- ==========================================

DROP TABLE IF EXISTS silver.dim_customer CASCADE;
CREATE TABLE silver.dim_customer (
    customer_key   SERIAL PRIMARY KEY,
    cust_id        INTEGER UNIQUE,
    first_name     VARCHAR(100),
    last_name      VARCHAR(100),
    email          VARCHAR(150),
    gender         VARCHAR(20),
    is_active      BOOLEAN DEFAULT TRUE,
    created_date   DATE,
    updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.dim_products CASCADE;
CREATE TABLE silver.dim_products (
    product_key   SERIAL PRIMARY KEY,
    prod_id       INTEGER UNIQUE,
    prod_name     VARCHAR(150) NOT NULL,
    category      VARCHAR(100),
    price         NUMERIC(10, 2),
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.fact_products_sales CASCADE;
CREATE TABLE silver.fact_products_sales (
    sale_key      SERIAL PRIMARY KEY,
    sale_id       INTEGER UNIQUE,
    customer_key  INTEGER REFERENCES silver.dim_customer(customer_key),
    product_key   INTEGER REFERENCES silver.dim_products(product_key),
    qty           INTEGER,
    total_price   NUMERIC(12, 2),
    sale_date     DATE,
    loaded_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 3. AUDIT SCHEMA TABLES (Metadata / Logging)
-- ==========================================

DROP TABLE IF EXISTS audit.load_logs CASCADE;
CREATE TABLE audit.load_logs (
    log_id          SERIAL PRIMARY KEY,
    procedure_name  VARCHAR(100) NOT NULL,
    step_name       VARCHAR(100) NOT NULL,
    status          VARCHAR(50) NOT NULL, -- 'SUCCESS', 'FAILED', 'INFO'
    records_loaded  INTEGER DEFAULT 0,
    error_message   TEXT,
    error_state     VARCHAR(5),
    logged_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
