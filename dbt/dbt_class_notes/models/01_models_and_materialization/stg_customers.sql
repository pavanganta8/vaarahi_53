-- Staging models clean, rename, and standardize raw data.
-- They are materialized as VIEWS because they represent lightweight layers on top of raw source data.

{{ config(
    materialized='view'
) }}

with source as (
    -- The source() macro sets up lineage between raw tables (in sources.yml) and staging models
    select * from {{ source('raw_source', 'raw_customers_source') }}
),

renamed as (
    select
        id as customer_id,
        first_name,
        last_name,
        email as customer_email,
        -- Standardizing date format / casting
        cast(signup_date as date) as signup_date
    from source
)

select * from renamed
