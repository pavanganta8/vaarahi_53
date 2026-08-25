with source as (
    select * from {{ source('bronze', 'crm_cust_info') }}
),
deduped as (
    select
        *,
        row_number() over (partition by cst_id order by cst_create_date desc) as flag_last
    from source
    where cst_id is not null
)
select
    cst_id,
    cst_key,
    trim(cst_firstname) as cst_firstname,
    trim(cst_lastname) as cst_lastname,
    case
        when upper(trim(cst_marital_status)) = 'S' then 'Single'
        when upper(trim(cst_marital_status)) = 'M' then 'Married'
        else 'n/a'
    end as cst_marital_status,
    case
        when upper(trim(cst_gndr)) = 'F' then 'Female'
        when upper(trim(cst_gndr)) = 'M' then 'Male'
        else 'n/a'
    end as cst_gndr,
    cst_create_date
from deduped
where flag_last = 1
