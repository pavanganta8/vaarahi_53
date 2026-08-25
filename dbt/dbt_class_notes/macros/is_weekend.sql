-- Custom macro to check if a date is a weekend.
-- Note: extract(dow from ...) works in Postgres. For Snowflake, use dayofweek.

{% macro is_weekend(date_column) %}
    case
        when extract(dow from {{ date_column }}) in (0, 6) then true
        else false
    end
{% endmacro %}
