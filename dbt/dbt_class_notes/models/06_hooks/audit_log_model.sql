-- This model demonstrates model-specific hooks configured in the `config()` block.
-- Here we run pre-hooks and post-hooks to insert start and end timestamps into an audit table.

{{ config(
    materialized='table',
    pre_hook=[
        "select 1; -- Pre-hook: e.g. insert into audit_log values ('{{ this.name }}', 'STARTED', current_timestamp)"
    ],
    post_hook=[
        "select 2; -- Post-hook: e.g. insert into audit_log values ('{{ this.name }}', 'COMPLETED', current_timestamp)",
        "select 3; -- Post-hook: e.g. grant select on {{ this }} to role analyst_role"
    ]
) }}

-- The actual model transformation logic
with customers as (
    select * from {{ ref('dim_customers') }}
)

select
    customer_id,
    full_name,
    customer_email,
    signup_date,
    -- Custom tracking columns
    'COMPLETED' as status,
    current_timestamp as last_modified_at
from customers
