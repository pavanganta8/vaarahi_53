with sd as (
    select * from {{ ref('stg_crm_sales_details') }}
),
pr as (
    select * from {{ ref('dim_products') }}
),
cu as (
    select * from {{ ref('dim_customers') }}
)
select
    sd.sls_ord_num  as order_number,
    pr.product_key  as product_key,
    cu.customer_key as customer_key,
    sd.sls_order_dt as order_date,
    sd.sls_ship_dt  as shipping_date,
    sd.sls_due_dt   as due_date,
    sd.sls_sales    as sales_amount,
    sd.sls_quantity as quantity,
    sd.sls_price    as price
from sd
left join pr
    on sd.sls_prd_key = pr.product_number
left join cu
    on sd.sls_cust_id = cu.customer_id
where date_trunc(sd.sls_order_dt, month) = date_trunc(current_date(), month)
