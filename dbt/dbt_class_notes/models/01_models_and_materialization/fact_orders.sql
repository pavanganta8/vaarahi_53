-- Incremental models are designed to process only new or updated records to save execution time and cost.
-- On the first run, dbt creates the full table. On subsequent runs, it appends only the matching records.

{{ config(
    materialized='incremental',
    unique_key='order_id',          -- Ensures rows are merged/updated rather than blindly appended
    on_schema_change='fail'         -- Instructs dbt on how to handle structural changes in the source
) }}

with source_orders as (
    select * from {{ source('raw_source', 'raw_orders_source') }}
)

select
    id as order_id,
    customer_id,
    order_date,
    status,
    amount
from source_orders

-- The `is_incremental()` macro checks if the table exists and if the model is NOT run as a full refresh
{% if is_incremental() %}
    -- Only load rows that are newer than the newest row already in the destination table
    -- `{{ this }}` refers to the destination table name as it exists in the database
    where order_date > (select max(order_date) from {{ this }})
{% endif %}
