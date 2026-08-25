# 🪝 Hooks in DBT

Hooks are SQL commands that execute at specific times during a dbt run. They are critical for security grants, audit logging, setting indexes, or cleaning up schemas before and after dbt compiles.

---

## 1. Types of Hooks

| Hook Type | Scope | When It Runs | Use Cases |
| :--- | :--- | :--- | :--- |
| **`on-run-start`** | Project-level | Before any model or seed starts executing. | Creating a master audit schema, enabling session variables. |
| **`pre-hook`** | Model-level | Immediately **before** a specific model is built. | Creating temporary table spaces, vacuuming, deleting old partitions. |
| **`post-hook`** | Model-level | Immediately **after** a specific model is built. | Granting `SELECT` privileges, inserting logs into an audit table, building indexes. |
| **`on-run-end`** | Project-level | After all models, tests, and seeds complete. | Committing audit logs, cleaning up workspace tables. |

---

## 2. Where to Configure Hooks

### 📂 Option A: In `dbt_project.yml` (Project-wide)
Applies the hook automatically to all models in a folder.
```yaml
models:
  dbt_class_notes:
    marts:
      +post-hook:
        - "grant select on {{ this }} to role reporting_role;"
```

### 📄 Option B: In Model Files (Model-specific)
Applies the hook only to that specific model inside the config block.
```sql
{{ config(
    materialized='table',
    post_hook=[
      "grant select on {{ this }} to role reader_role"
    ]
) }}
```

---

## 3. Transaction Boundaries
By default, model pre- and post-hooks execute inside the same database transaction as the model build itself. If you want a hook to execute outside the transaction (e.g. running a `VACUUM` command that cannot run inside a transaction block), you can wrap it in an `after_commit` hook syntax or specify transactions in configuration.
* **Example in this folder**: [audit_log_model.sql](audit_log_model.sql)
