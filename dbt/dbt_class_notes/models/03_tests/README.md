# 🧪 Testing in DBT

Testing is a core feature in dbt that ensures data quality, validity, and integrity. dbt provides two main categories of tests: **Generic Tests** and **Singular Tests**.

---

## 1. Generic Tests
* **What they are**: Reusable parameterized queries defined on columns inside your schema/documentation `.yml` files.
* **Core Built-in Tests**:
  * `unique`: Asserts that all values in a column are distinct.
  * `not_null`: Asserts that a column contains no null values.
  * `accepted_values`: Asserts that column values fall within a predefined list (e.g. status must be 'placed', 'shipped', etc.).
  * `relationships`: Asserts that a column is a foreign key pointing to a primary key in another table (referential integrity).
* **Example configuration**: See [schema.yml](schema.yml)

## 2. Singular Tests
* **What they are**: A custom SQL query saved in your project's `tests/` folder.
* **How they work**: If the query returns **zero** records, the test passes. If it returns **any** rows, the test fails.
* **When to use**: Custom business logic constraints, such as "orders cannot have negative prices" or "shipping date cannot precede order date."
* **Example in project**: [singular_assert_positive_orders.sql](../../tests/singular_assert_positive_orders.sql)

## 3. Custom Generic Tests
* **What they are**: Custom macros defined in the `macros/` folder that act as schema tests.
* **Benefits**: If a singular test logic needs to be run on multiple columns across multiple tables, we turn it into a custom generic test (e.g. `test_is_even`).
* **Example code**: See [macros/test_is_even.sql](../../macros/test_is_even.sql)

---

## ⚙️ Test Configurations (Severity & Thresholds)

By default, any row failure fails a test with `error` severity, halting CI/CD runs. You can configure:
1. **Severity Level**: Set `severity: warn` if a failure is acceptable but should trigger an alert.
2. **Failure Thresholds**: Configure DBT to only trigger an error if the number of failing rows exceeds a threshold using `warn_if` or `error_if`.

```yaml
tests:
  - unique:
      config:
        severity: warn
        warn_if: ">10"  # Fail with warning only if more than 10 rows fail
```
