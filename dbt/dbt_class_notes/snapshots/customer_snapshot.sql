-- This snapshot tracks changes to our customer data using the `check` strategy.
-- We use this strategy because the raw customer data does not have an `updated_at` column.

{% snapshot customer_snapshot %}

{{
    config(
      target_schema='snapshots',          -- Target schema for snapshot storage
      unique_key='id',                     -- Unique row key
      strategy='check',                    -- Check columns directly for changes
      check_cols=['first_name', 'last_name', 'email'] -- Columns to compare
    )
}}

select 
    id, 
    first_name, 
    last_name, 
    email 
from {{ ref('raw_customers') }}

{% endsnapshot %}
