-- Singular tests return rows that violate database integrity or business logic.
-- If this query returns ANY rows, the test fails. If it returns 0 rows, the test passes.
-- Business Logic: An order's monetary amount must always be greater than or equal to 0.

select
    order_id,
    amount
from {{ ref('fact_orders') }}
where amount < 0
