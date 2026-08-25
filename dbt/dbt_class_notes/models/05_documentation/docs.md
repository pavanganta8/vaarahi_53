-- This is a markdown documentation file. dbt parses the {% docs %} tags to populate the UI catalog.

{% docs customer_overview %}

This model represents clean, audit-compliant **customer data** used for downstream reporting and dashboard metrics.

### Key Cleaning Operations:
1. Trims whitespace from `first_name` and `last_name`.
2. Standardizes email addresses to lower-case.
3. Automatically derives a consolidated `full_name` column.
4. Drops raw, unvalidated record duplicates.

### Downstream Stakeholders:
* Marketing Team (for email campaigns)
* Sales Operations (for buyer demographics)

{% enddocs %}
