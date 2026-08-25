-- This model demonstrates the power of Jinja templating, variables, macros, and loops.
-- It will compile down to raw SQL before executing on the database.

{{ config(
    materialized='view'
) }}

-- Define a local Jinja list of payment methods to iterate over
{% set payment_methods = ['credit_card', 'bank_transfer', 'gift_card'] %}

with source_orders as (
    select * from {{ source('raw_source', 'raw_orders_source') }}
)

select
    id as order_id,
    customer_id,
    order_date,
    
    -- 1. Calling our custom calculation macro
    {{ cents_to_dollars('amount_cents') }} as order_amount_usd,
    
    -- 2. Calling our custom conditional logic macro
    {{ is_weekend('order_date') }} as is_placed_on_weekend,
    
    -- 3. Referencing a global variable defined in dbt_project.yml
    '{{ var("current_academic_year") }}' as academic_year_label,
    
    -- 4. Using a Jinja For Loop to dynamically pivot transaction methods into columns
    {% for method in payment_methods %}
    case 
        when payment_method = '{{ method }}' then {{ cents_to_dollars('amount_cents') }} 
        else 0 
    end as {{ method }}_amount{% if not loop.last %},{% endif %}
    {% endfor %}

from source_orders
