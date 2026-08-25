-- =====================================================================
-- TOPIC: ROLE-BASED ACCESS CONTROL (RBAC) & USER ACCESS IN SNOWFLAKE
-- =====================================================================
-- Explanation:
-- 1. Snowflake uses Role-Based Access Control (RBAC). Privileges are granted 
--    to ROLES, and roles are granted to USERS.
-- 2. System-defined roles (from highest to lowest privilege):
--    - ORGADMIN: Manage organizations and accounts.
--    - ACCOUNTADMIN: Super-user; manages account level settings and billing.
--    - SECURITYADMIN: Manages security objects, users, roles, and grants.
--    - USERADMIN: Dedicated role to manage user and role creation.
--    - SYSADMIN: Creates databases, schemas, warehouses, and tables.
--    - PUBLIC: Automatically granted to every user; lowest privilege.
-- 3. Best Practice: Grant custom roles to SYSADMIN to maintain a clean role hierarchy.
-- =====================================================================

-- =====================================================================
-- Step 1: Create Custom Roles (Best to run as USERADMIN or SECURITYADMIN)
-- =====================================================================
USE ROLE USERADMIN;

CREATE OR REPLACE ROLE developer_role;
CREATE OR REPLACE ROLE analyst_role;


-- =====================================================================
-- Step 2: Establish Role Hierarchy (Grant custom roles to SYSADMIN)
-- =====================================================================
-- This allows SYSADMIN to view and manage objects created by these roles.
USE ROLE SECURITYADMIN;

GRANT ROLE developer_role TO ROLE SYSADMIN;
GRANT ROLE analyst_role TO ROLE SYSADMIN;


-- =====================================================================
-- Step 3: Create Users and Assign Roles
-- =====================================================================
USE ROLE USERADMIN;

CREATE OR REPLACE USER john_dev
  PASSWORD = 'TemporaryPassword123!'
  MUST_CHANGE_PASSWORD = TRUE
  DEFAULT_ROLE = developer_role;

CREATE OR REPLACE USER sarah_analyst
  PASSWORD = 'TemporaryPassword456!'
  MUST_CHANGE_PASSWORD = TRUE
  DEFAULT_ROLE = analyst_role;

-- Assign the roles to the users
USE ROLE SECURITYADMIN;
GRANT ROLE developer_role TO USER john_dev;
GRANT ROLE analyst_role TO USER sarah_analyst;


-- =====================================================================
-- Step 4: Grant Object-Level Privileges to Roles
-- =====================================================================
USE ROLE SYSADMIN;

-- Create warehouse, database, and schema to demonstrate privileges
CREATE OR REPLACE WAREHOUSE dev_wh WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60;
CREATE OR REPLACE DATABASE dev_db;
CREATE OR REPLACE SCHEMA dev_db.raw_data;

CREATE OR REPLACE TABLE dev_db.raw_data.customers (
    id INT,
    name VARCHAR(100)
);

-- Grant privileges to developer_role
USE ROLE SECURITYADMIN;

-- Usage privileges on virtual compute (Warehouse)
GRANT USAGE ON WAREHOUSE dev_wh TO ROLE developer_role;

-- Usage privileges on container objects (Database and Schema)
GRANT USAGE ON DATABASE dev_db TO ROLE developer_role;
GRANT USAGE ON SCHEMA dev_db.raw_data TO ROLE developer_role;

-- Object level privilege on tables (Select, Insert, Update)
GRANT SELECT, INSERT, UPDATE ON TABLE dev_db.raw_data.customers TO ROLE developer_role;


-- =====================================================================
-- Step 5: Future Grants (Highly recommended for automation)
-- =====================================================================
-- Automatically grant privileges on tables created in the future within the schema.
GRANT SELECT ON FUTURE TABLES IN SCHEMA dev_db.raw_data TO ROLE analyst_role;


-- =====================================================================
-- Step 6: Querying Privileges and Auditing
-- =====================================================================
-- Show all roles in the account
SHOW ROLES;

-- See who has been granted a specific role
SHOW GRANTS OF ROLE developer_role;

-- See all roles and privileges granted to a specific user
SHOW GRANTS TO USER john_dev;

-- See what privileges a specific role holds
SHOW GRANTS TO ROLE developer_role;

-- See who has what privileges on a specific table
SHOW GRANTS ON TABLE dev_db.raw_data.customers;
