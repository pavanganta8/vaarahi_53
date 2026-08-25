-- Custom generic test to assert that values in a column are even numbers.
-- Custom tests return rows that FAIL the condition (i.e. number is odd).

{% test is_even(model, column_name) %}

select
    {{ column_name }}
from {{ model }}
-- Return any records where the value modulo 2 is not equal to 0
where ({{ column_name }} % 2) != 0
  and {{ column_name }} is not null

{% endtest %}
