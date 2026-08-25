# 🎓 DBT (Data Build Tool) Classroom & Notes Repository

Welcome to your hands-on DBT study guide! This project is structured as a self-contained, topic-wise course designed to teach you DBT from scratch, covering foundational to advanced analytics engineering concepts.

---

## 📚 Curriculum & Folder Structure

This repository is organized topic-by-topic to take you from a dbt beginner to an expert. Each folder contains its own `README.md` with in-depth notes and relevant models.

### 📁 1. Models & Materializations (`models/01_models_and_materialization/`)
Learn the building blocks of DBT models and how to transform data.
* **Topics covered**: View, Table, Ephemeral (subquery/CTE style), and Incremental materializations.
* **Key Files**:
  * [stg_customers.sql](models/01_models_and_materialization/stg_customers.sql) - View
  * [int_customers_cleansed.sql](models/01_models_and_materialization/int_customers_cleansed.sql) - Ephemeral
  * [dim_customers.sql](models/01_models_and_materialization/dim_customers.sql) - Table
  * [fact_orders.sql](models/01_models_and_materialization/fact_orders.sql) - Incremental

### 📁 2. Seeds & Sources (`seeds/` & `models/02_seeds_and_sources/`)
Learn how to load static lookup files and configure external raw data.
* **Topics covered**: Seeds configuration, CSV load, Sources (`sources.yml`), and source freshness checks.
* **Key Files**:
  * [raw_customers.csv](seeds/raw_customers.csv) - Customer CSV dataset
  * [raw_products.csv](seeds/raw_products.csv) - Product pricing CSV dataset
  * [sources.yml](models/sources.yml) - Declaring external sources
  * [stg_products.sql](models/02_seeds_and_sources/stg_products.sql) - Sourcing from seeds & sources

### 📁 3. Testing (`models/03_tests/` & `tests/`)
Learn how to ensure data quality and build confidence in your pipelines.
* **Topics covered**: Generic tests (unique, not null, accepted values, relationships), custom tests, severity thresholds (`warn` vs `error`), and singular SQL assertions.
* **Key Files**:
  * [schema.yml](models/03_tests/schema.yml) - Configured schema-level tests
  * [singular_assert_positive_orders.sql](tests/singular_assert_positive_orders.sql) - Singular query-based test

### 📁 4. Macros & Jinja (`macros/` & `models/04_macros_and_jinja/`)
Bring programming power (dry code, loops, conditionals) to SQL.
* **Topics covered**: Custom macros, Jinja control flows (for loops, if/else), target overrides, and custom generic tests.
* **Key Files**:
  * [cents_to_dollars.sql](macros/cents_to_dollars.sql) - Basic macro
  * [is_weekend.sql](macros/is_weekend.sql) - Jinja if/else logic
  * [test_is_even.sql](macros/test_is_even.sql) - Defining a custom generic test using a macro
  * [stg_orders.sql](models/04_macros_and_jinja/stg_orders.sql) - Model demonstrating Jinja looping and custom macro usage

### 📁 5. Documentation (`models/05_documentation/`)
Write rich data catalogs and document schemas.
* **Topics covered**: Schema YAML descriptions, Doc blocks (`docs.md` & `{% docs %}` tags), and running/hosting the documentation site.
* **Key Files**:
  * [docs.md](models/05_documentation/docs.md) - Rich text documentation block
  * [schema.yml](models/05_documentation/schema.yml) - Linking descriptions to documentation site

### 📁 6. Hooks (`models/06_hooks/`)
Run database administration scripts integrated within your ETL runtime.
* **Topics covered**: Pre-hooks, post-hooks, project-level vs. model-level hooks, and auditing logs.
* **Key Files**:
  * [audit_log_model.sql](models/06_hooks/audit_log_model.sql) - Demonstrates hooks firing SQL statements before & after executing a model

### 📁 7. Snapshots (`snapshots/`)
Track history and implement Type 2 Slowly Changing Dimensions (SCD Type 2).
* **Topics covered**: Timestamp strategy (updated_at) vs. Check strategy (hashing columns).
* **Key Files**:
  * [product_snapshot.sql](snapshots/product_snapshot.sql) - Timestamp strategy
  * [customer_snapshot.sql](snapshots/customer_snapshot.sql) - Check strategy

---

## 🛠️ Essential DBT Commands Reference

Here are the primary commands you will use to interact with this project:

```bash
# 1. Install external package dependencies defined in packages.yml
dbt deps

# 2. Upload CSV data files in the seeds directory into the warehouse
dbt seed

# 3. Compile and build all models (creates views/tables in the DB)
dbt run

# 4. Compile and run all tests (generic and singular)
dbt test

# 5. Run a specific model
dbt run --select stg_customers

# 6. Run a model and its downstream dependents
dbt run --select stg_customers+

# 7. Generate and compile HTML documentation website
dbt docs generate

# 8. Start a local server to view the generated documentation site
dbt docs serve
```
