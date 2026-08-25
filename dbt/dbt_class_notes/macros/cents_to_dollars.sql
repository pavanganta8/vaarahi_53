-- Custom macro to convert cents to dollars.
-- Arguments:
--   - column_name: the database column containing cent values.
--   - scale: decimal precision (defaults to 2).

{% macro cents_to_dollars(column_name, scale=2) %}
    round(
        cast({{ column_name }} as numeric) / 100, 
        {{ scale }}
    )
{% endmacro %}
