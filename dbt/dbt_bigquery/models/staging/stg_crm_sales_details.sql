with source as (
    select * from {{ source('bronze', 'crm_sales_details') }}
)
select
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    case
        when sls_order_dt = 0 or length(cast(sls_order_dt as string)) != 8 then null
        else parse_date('%Y%m%d', cast(sls_order_dt as string))
    end as sls_order_dt,
    case
        when sls_ship_dt = 0 or length(cast(sls_ship_dt as string)) != 8 then null
        else parse_date('%Y%m%d', cast(sls_ship_dt as string))
    end as sls_ship_dt,
    case
        when sls_due_dt = 0 or length(cast(sls_due_dt as string)) != 8 then null
        else parse_date('%Y%m%d', cast(sls_due_dt as string))
    end as sls_due_dt,
    case
        when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * abs(sls_price)
            then sls_quantity * abs(sls_price)
        else sls_sales
    end as sls_sales,
    sls_quantity,
    case
        when sls_price is null or sls_price <= 0
            then cast(sls_sales / nullif(sls_quantity, 0) as int64)
        else sls_price
    end as sls_price
from source
