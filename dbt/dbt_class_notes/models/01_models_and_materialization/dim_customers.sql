-- Dimension models are usually materialized as TABLES to optimize query performance for BI and reports.
-- Every time `dbt run` executes, this table is fully replaced in a single transaction (drop and recreate).

{{ config(
    materialized='table'
) }}

with customers as (
    -- Reference our ephemeral cleansed customer model
    select * from {{ ref('int_customers_cleansed') }}
)

select
    customer_id,
    first_name,
    last_name,
    full_name,
    customer_email,
    signup_date,
    -- In a real project, we might join aggregations here (e.g. total lifetime orders)
    current_timestamp as dbt_loaded_at
from customers
