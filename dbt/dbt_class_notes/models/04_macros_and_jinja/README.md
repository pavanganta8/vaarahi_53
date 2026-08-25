# 🪄 Macros & Jinja in DBT

Jinja is a templating engine that allows you to write Python-like control structures, variables, loops, and conditions directly inside your SQL files. In dbt, these templated snippets are compiled into raw SQL before running in the database.

---

## 1. What is Jinja?
Jinja runs **before** SQL compiles. It allows you to:
* Parameterize SQL queries (using `{{ var('variable_name') }}`).
* Implement control flows (loops and conditionals).
* Reference other models dynamically (`{{ ref('model_name') }}`).

## 2. What are Macros?
* **Definition**: Macros are reusable Jinja snippets, similar to functions in Python. They are defined in the `macros/` folder and can be called from any model in the project.
* **Why use them**: To keep your code DRY (Don't Repeat Yourself). Instead of repeating complex formulas or conditional clauses across multiple SQL models, you write a macro and call it.
* **Example**: [cents_to_dollars.sql](../../macros/cents_to_dollars.sql)

## 3. Jinja Control Structures

### 🟢 Conditionals (If/Else)
Useful for writing conditional SQL dialects or switching logic depending on environment variables.
```sql
{% if target.name == 'prod' %}
  select * from prod_table
{% else %}
  select * from dev_table
{% endif %}
```
* **Example**: [is_weekend.sql](../../macros/is_weekend.sql)

### 🔄 Loops (For loops)
Extremely powerful for dynamic operations, like pivoting rows into columns or running a calculation across a list of column names.
```sql
{% for payment_method in ['credit_card', 'coupon', 'bank_transfer'] %}
  sum(case when payment_method = '{{ payment_method }}' then amount else 0 end) as {{ payment_method }}_amount
  {% if not loop.last %},{% endif %}
{% endfor %}
```
* **Example**: See this in action in [stg_orders.sql](stg_orders.sql)

---

## 4. Custom Generic Tests
Macros are also used to define custom testing logic. Any macro prefixed with `test_` becomes a custom test schema that can be applied to columns.
* **Example**: [test_is_even.sql](../../macros/test_is_even.sql) is applied as a test.
