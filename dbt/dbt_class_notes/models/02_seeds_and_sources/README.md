# 💡 Seeds vs. Sources in DBT

Understanding how data enters your dbt DAG (Directed Acyclic Graph) is critical. dbt handles incoming data in two distinct ways: **Seeds** and **Sources**.

---

## 1. Seeds
* **What they are**: Static or slow-moving lookup tables defined as local CSV files inside your dbt project's `seeds/` folder.
* **How they load**: Running the command `dbt seed` reads these CSVs and uploads them as physical tables directly into the warehouse.
* **When to use**: Lookup tables, lists of country codes, mapping tables, employees list, marketing channel mapping, or tax rates.
* **When NOT to use**: Production data, transaction logs, large tables, or data that changes frequently (e.g. daily/hourly). Storing large or fast-moving files in git is an anti-pattern.
* **Syntax to reference**: `{{ ref('raw_products') }}` (referenced just like a normal model).
* **Example in this folder**: [stg_products.sql](stg_products.sql) loads from a seed.

## 2. Sources
* **What they are**: Raw tables already loaded into your database by an ingestion tool (like Fivetran, Airbyte, Stitch, or a custom script) that dbt references.
* **How they load**: dbt **does not** load source data. It only reads from sources. You document sources in a `sources.yml` schema file.
* **When to use**: All transaction data, application tables, logging dumps, and general warehouse input tables.
* **Syntax to reference**: `{{ source('source_name', 'table_name') }}` (e.g., `{{ source('raw_source', 'raw_customers_source') }}`).
* **Benefits**: 
  * Allows you to track data lineage from raw files to BI tables.
  * Allows running source freshness checks to monitor ingestion pipelines.
  * Protects code from hardcoded database paths.
