-- Staging model loading from a seed instead of a source.
-- Because seeds behave like models, we reference them using the `ref()` function.

{{ config(
    materialized='view'
) }}

with seed_data as (
    select * from {{ ref('raw_products') }}
)

select
    id as product_id,
    name as product_name,
    category,
    price,
    -- Standardizing the timestamp format
    cast(updated_at as timestamp) as updated_at
from seed_data
