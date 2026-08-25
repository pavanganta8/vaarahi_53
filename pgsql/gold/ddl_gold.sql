/*
===============================================================================
DDL Script: Create Gold Tables (PostgreSQL)
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
DROP TABLE IF EXISTS gold.dim_customers CASCADE;

CREATE TABLE gold.dim_customers (
    customer_key       INT,
    customer_id        INT,
    customer_number    VARCHAR(50),
    first_name         VARCHAR(50),
    last_name          VARCHAR(50),
    country            VARCHAR(50),
    marital_status     VARCHAR(50),
    gender             VARCHAR(50),
    birthdate          DATE,
    create_date        DATE
);

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
DROP TABLE IF EXISTS gold.dim_products CASCADE;

CREATE TABLE gold.dim_products (
    product_key        INT,
    product_id         INT,
    product_number     VARCHAR(50),
    product_name       VARCHAR(50),
    category_id        VARCHAR(50),
    category           VARCHAR(50),
    subcategory        VARCHAR(50),
    maintenance        VARCHAR(50),
    cost               INT,
    product_line       VARCHAR(50),
    start_date         DATE
);

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
DROP TABLE IF EXISTS gold.fact_sales CASCADE;

CREATE TABLE gold.fact_sales (
    order_number       VARCHAR(50),
    product_key        INT,
    customer_key       INT,
    order_date         DATE,
    shipping_date      DATE,
    due_date           DATE,
    sales_amount       INT,
    quantity           INT,
    price              INT
);
