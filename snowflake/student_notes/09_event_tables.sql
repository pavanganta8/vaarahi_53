-- =====================================================================
-- TOPIC: EVENT TABLES (LOGGING & TRACING) IN SNOWFLAKE
-- =====================================================================
-- Explanation:
-- 1. Event Tables are designed to store log and trace data from Stored
--    Procedures, User-Defined Functions (UDFs), and User-Defined Table Functions.
-- 2. Once set up, Snowflake automatically routes telemetry messages to the table.
-- 3. You can log messages from Python, Java, Scala, JavaScript, or SQL UDFs.
-- =====================================================================

-- Step 1: Create an Event Table
-- Event tables have a pre-defined schema, so you don't need to specify columns!
CREATE OR REPLACE EVENT TABLE student_notes.public.my_telemetry_event_table;


-- Step 2: Associate the Event Table with the Account
-- (Note: Requires ACCOUNTADMIN role to set account level configuration)
USE ROLE ACCOUNTADMIN;
ALTER ACCOUNT SET EVENT_TABLE = student_notes.public.my_telemetry_event_table;


-- Step 3: Set Logging and Tracing Levels for a Database/Schema
-- Valid levels: OFF, FATAL, ERROR, WARN, INFO, DEBUG, TRACE
ALTER DATABASE student_notes SET LOG_LEVEL = 'INFO';
ALTER DATABASE student_notes SET TRACE_LEVEL = 'ALWAYS';


-- Step 4: Write a Stored Procedure in Python that generates logs
-- This procedure uses Python's standard 'logging' module.
CREATE OR REPLACE PROCEDURE student_notes.public.log_test_procedure()
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('snowflake-telemetry-python')
HANDLER = 'main'
AS
$$
import logging
logger = logging.getLogger("my_logger")

def main(session):
    logger.info("Executing the log test procedure.")
    logger.warning("This is a warning log message from Python!")
    try:
        x = 1 / 0
    except ZeroDivisionError as e:
        logger.error(f"Encountered a division by zero error: {str(e)}")
    
    return "Logging complete!"
$$;


-- Step 5: Run the Stored Procedure to generate log records
CALL student_notes.public.log_test_procedure();


-- Step 6: Query logs from the Event Table
-- (Telemetry logs might take a few minutes to be flushed to the table)
SELECT 
    TIMESTAMP,
    RECORD_TYPE, -- 'LOG' or 'SPAN'
    SCOPE:name::VARCHAR AS LOG_SOURCE,
    RECORD:severity::VARCHAR AS SEVERITY,
    RECORD:body::VARCHAR AS LOG_MESSAGE
FROM student_notes.public.my_telemetry_event_table
ORDER BY TIMESTAMP DESC;
