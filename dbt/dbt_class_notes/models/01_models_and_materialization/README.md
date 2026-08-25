# 🛠️ DBT Materializations

Materializations are strategies for persisting dbt models in the warehouse. DBT supports four core types of materializations, which can be configured at the project level (`dbt_project.yml`) or directly within model files using the `config()` block.

---

## 1. View (default)
* **What it is**: Rebuilds the model as a database **VIEW** on every run using `CREATE VIEW AS ...`.
* **When to use**: Staging models, lightweight transformations, or when raw data updates frequently and you need real-time data without storage costs.
* **Pros**: Simple, fast to compile, consumes no additional storage, always up-to-date.
* **Cons**: Performance cost at query time because the underlying SQL runs whenever the view is queried.
* **Example in this folder**: [stg_customers.sql](stg_customers.sql)

## 2. Table
* **What it is**: Rebuilds the model as a physical database **TABLE** on every run using `CREATE TABLE AS ...` (or a drop/recreate transaction).
* **When to use**: Marts, presentation layer tables, complex reporting models queried by BI tools where fast query performance is critical.
* **Pros**: Queries against tables are much faster than queries against views because the calculation is pre-computed.
* **Cons**: Slower to compile/run during `dbt run` since data is physically written; consumes disk space.
* **Example in this folder**: [dim_customers.sql](dim_customers.sql)

## 3. Ephemeral
* **What it is**: Does **NOT** exist as a physical object in the database. Instead, DBT interpolates this model's code as a Common Table Expression (CTE) in any downstream model referencing it with `{{ ref('...') }}`.
* **When to use**: Internal helper models, cleansing tasks, or intermediate joins that are only used in one or two downstream models and do not need to be exposed to BI users.
* **Pros**: Keeps the database clean of clutter/helper tables.
* **Cons**: You cannot query ephemeral models directly from client tools; can make debugging harder.
* **Example in this folder**: [int_customers_cleansed.sql](int_customers_cleansed.sql)

## 4. Incremental
* **What it is**: Appends or updates only **NEW** or **CHANGED** data since the last time the model was run. It leverages the `is_incremental()` macro to insert delta logic.
* **When to use**: Very large event tables, transactional logs, or fact streams where rebuilding the whole table on every run is too slow or costly.
* **Pros**: Dramatic reductions in runtime and compute costs.
* **Cons**: Requires careful planning, configuring unique keys, managing schemas, and handling late-arriving dimensions.
* **Example in this folder**: [fact_orders.sql](fact_orders.sql)
