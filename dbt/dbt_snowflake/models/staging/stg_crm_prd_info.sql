with source as (
    select * from {{ source('bronze', 'crm_prd_info') }}
)
select
    prd_id,
    replace(substr(prd_key, 1, 5), '-', '_') as cat_id,
    substr(prd_key, 7) as prd_key,
    prd_nm,
    coalesce(prd_cost, 0) as prd_cost,
    case
        when upper(trim(prd_line)) = 'M' then 'Mountain'
        when upper(trim(prd_line)) = 'R' then 'Road'
        when upper(trim(prd_line)) = 'S' then 'Other Sales'
        when upper(trim(prd_line)) = 'T' then 'Touring'
        else 'n/a'
    end as prd_line,
    cast(prd_start_dt as date) as prd_start_dt,
    cast(
        dateadd(day, -1, lead(prd_start_dt) over (partition by prd_key order by prd_start_dt))
        as date
    ) as prd_end_dt
from source
