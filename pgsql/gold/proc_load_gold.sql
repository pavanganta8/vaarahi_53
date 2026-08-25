/*
===============================================================================
Stored Procedure: Load Gold Layer (Silver -> Gold) (PostgreSQL)
===============================================================================
*/
CREATE OR REPLACE PROCEDURE gold.load_gold()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    batch_start_time TIMESTAMP;
    batch_end_time TIMESTAMP;
BEGIN
    batch_start_time := clock_timestamp();
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Gold Layer';
    RAISE NOTICE '================================================';

    -- Loading gold.dim_customers
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.dim_customers';
    TRUNCATE TABLE gold.dim_customers;
    RAISE NOTICE '>> Inserting Data Into: gold.dim_customers';
    INSERT INTO gold.dim_customers (
        customer_key,
        customer_id,
        customer_number,
        first_name,
        last_name,
        country,
        marital_status,
        gender,
        birthdate,
        create_date
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
        ci.cst_id                          AS customer_id,
        ci.cst_key                         AS customer_number,
        ci.cst_firstname                   AS first_name,
        ci.cst_lastname                    AS last_name,
        la.cntry                           AS country,
        ci.cst_marital_status              AS marital_status,
        CASE 
            WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
            ELSE COALESCE(ca.gen, 'n/a')
        END                                AS gender,
        ca.bdate                           AS birthdate,
        ci.cst_create_date                 AS create_date
    FROM silver.crm_cust_info ci
    LEFT JOIN silver.erp_cust_az12 ca
        ON ci.cst_key = ca.cid
    LEFT JOIN silver.erp_loc_a101 la
        ON ci.cst_key = la.cid;
    end_time := clock_timestamp();
    RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> -------------';

    -- Loading gold.dim_products
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.dim_products';
    TRUNCATE TABLE gold.dim_products;
    RAISE NOTICE '>> Inserting Data Into: gold.dim_products';
    INSERT INTO gold.dim_products (
        product_key,
        product_id,
        product_number,
        product_name,
        category_id,
        category,
        subcategory,
        maintenance,
        cost,
        product_line,
        start_date
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
        pn.prd_id       AS product_id,
        pn.prd_key      AS product_number,
        pn.prd_nm       AS product_name,
        pn.cat_id       AS category_id,
        pc.cat          AS category,
        pc.subcat       AS subcategory,
        pc.maintenance  AS maintenance,
        pn.prd_cost     AS cost,
        pn.prd_line     AS product_line,
        pn.prd_start_dt AS start_date
    FROM silver.crm_prd_info pn
    LEFT JOIN silver.erp_px_cat_g1v2 pc
        ON pn.cat_id = pc.id
    WHERE pn.prd_end_dt IS NULL;
    end_time := clock_timestamp();
    RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> -------------';

    -- Loading gold.fact_sales
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: gold.fact_sales';
    TRUNCATE TABLE gold.fact_sales;
    RAISE NOTICE '>> Inserting Data Into: gold.fact_sales';
    INSERT INTO gold.fact_sales (
        order_number,
        product_key,
        customer_key,
        order_date,
        shipping_date,
        due_date,
        sales_amount,
        quantity,
        price
    )
    SELECT
        sd.sls_ord_num  AS order_number,
        pr.product_key  AS product_key,
        cu.customer_key AS customer_key,
        sd.sls_order_dt AS order_date,
        sd.sls_ship_dt  AS shipping_date,
        sd.sls_due_dt   AS due_date,
        sd.sls_sales    AS sales_amount,
        sd.sls_quantity AS quantity,
        sd.sls_price    AS price
    FROM silver.crm_sales_details sd
    LEFT JOIN gold.dim_products pr
        ON sd.sls_prd_key = pr.product_number
    LEFT JOIN gold.dim_customers cu
        ON sd.sls_cust_id = cu.customer_id
    WHERE DATE_TRUNC('month', sd.sls_order_dt) = DATE_TRUNC('month', CURRENT_DATE);
    end_time := clock_timestamp();
    RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> -------------';

    batch_end_time := clock_timestamp();
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Loading Gold Layer is Completed';
    RAISE NOTICE '   - Total Load Duration: % seconds', EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
    RAISE NOTICE '==========================================';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'ERROR OCCURED DURING LOADING GOLD LAYER';
    RAISE NOTICE 'Error Message: %', SQLERRM;
    RAISE NOTICE 'Error State: %', SQLSTATE;
    RAISE NOTICE '==========================================';
END;
$$;
