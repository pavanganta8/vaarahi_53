-- Ephemeral models do not exist as physical tables or views in the database.
-- Instead, dbt embeds this query as a Common Table Expression (CTE) inside any downstream query referencing it.
-- Excellent for internal cleaning steps that should not clutter the database schema.

{{ config(
    materialized='ephemeral'
) }}

with customers as (
    select * from {{ ref('stg_customers') }}
)

select
    customer_id,
    -- Simple cleaning logic: trim and handle nulls
    trim(first_name) as first_name,
    trim(last_name) as last_name,
    lower(customer_email) as customer_email,
    signup_date,
    -- Derived field
    coalesce(trim(first_name), '') || ' ' || coalesce(trim(last_name), '') as full_name
from customers
