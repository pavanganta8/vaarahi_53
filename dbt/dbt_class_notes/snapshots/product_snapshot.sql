-- Snapshots are defined using a {% snapshot %} block instead of a standard model select.
-- This snapshot tracks changes to our products catalog using the `timestamp` strategy.

{% snapshot product_snapshot %}

{{
    config(
      target_schema='snapshots',      -- Schema where snapshot tables will be stored
      unique_key='id',                 -- The primary key of the source record
      strategy='timestamp',            -- Check for updates using a timestamp column
      updated_at='updated_at'          -- The source column representing last update
    )
}}

-- The select statement that defines the source dataset to snapshot
select 
    id, 
    name, 
    category, 
    price, 
    updated_at 
from {{ ref('raw_products') }}

{% endsnapshot %}
