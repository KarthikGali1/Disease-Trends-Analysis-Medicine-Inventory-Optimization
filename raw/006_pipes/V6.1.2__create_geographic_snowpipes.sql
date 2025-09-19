-- File: raw/V1.3.0__create_snowpipe_monitoring.sql
-- Description: Create monitoring and audit procedures for Snowpipes
-- Author: Data Engineering Team
-- Date: 2025-01-XX

USE SCHEMA staging;

-- ============================================================================
-- ENHANCED AUDIT LOG TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS snowpipe_audit_log (
  table_name VARCHAR(100),
  pipe_name VARCHAR(100),
  file_name VARCHAR(500),
  record_count INTEGER,
  load_timestamp TIMESTAMP_NTZ,
  file_size_bytes INTEGER,
  status VARCHAR(50),
  error_message VARCHAR(1000)
);

-- ============================================================================
-- MONITORING STORED PROCEDURES
-- ============================================================================

-- Procedure to check all pipe statuses
CREATE OR REPLACE PROCEDURE check_all_pipes_status_sp()
RETURNS TABLE (pipe_name STRING, status STRING, last_received_message_timestamp STRING)
LANGUAGE SQL
AS
$$
DECLARE
  res RESULTSET;
BEGIN
  res := (
    SELECT 
      'pipe_load_patients' as pipe_name,
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_patients')):"executionState"::STRING as status,
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_patients')):"lastReceivedMessageTimestamp"::STRING as last_received_message_timestamp
    UNION ALL
    SELECT 
      'pipe_load_drugs',
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_drugs')):"executionState"::STRING,
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_drugs')):"lastReceivedMessageTimestamp"::STRING
    UNION ALL
    SELECT 
      'pipe_load_suppliers',
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_suppliers')):"executionState"::STRING,
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_suppliers')):"lastReceivedMessageTimestamp"::STRING
    UNION ALL
    SELECT 
      'pipe_load_hospitals',
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_hospitals')):"executionState"::STRING,
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_hospitals')):"lastReceivedMessageTimestamp"::STRING
    UNION ALL
    SELECT 
      'pipe_load_inventory',
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_inventory')):"executionState"::STRING,
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_inventory')):"lastReceivedMessageTimestamp"::STRING
    UNION ALL
    SELECT 
      'pipe_load_healthcare_surveillance',
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_healthcare_surveillance')):"executionState"::STRING,
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_healthcare_surveillance')):"lastReceivedMessageTimestamp"::STRING
    UNION ALL
    SELECT 
      'pipe_load_prescriptions',
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_prescriptions')):"executionState"::STRING,
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_prescriptions')):"lastReceivedMessageTimestamp"::STRING
    UNION ALL
    SELECT 
      'pipe_load_geographic',
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_geographic')):"executionState"::STRING,
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_geographic')):"lastReceivedMessageTimestamp"::STRING
    UNION ALL
    SELECT 
      'pipe_load_diseases',
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_diseases')):"executionState"::STRING,
      PARSE_JSON(SYSTEM$PIPE_STATUS('pipe_load_diseases')):"lastReceivedMessageTimestamp"::STRING
  );
  RETURN TABLE(res);
END;
$$;

-- Procedure to get pipe load history
CREATE OR REPLACE PROCEDURE get_pipe_load_history_sp(days_back INTEGER DEFAULT 7)
RETURNS TABLE (pipe_name STRING, file_name STRING, load_time TIMESTAMP_NTZ, status STRING, row_count INTEGER, error_count INTEGER)
LANGUAGE SQL
AS
$$
DECLARE
  res RESULTSET;
BEGIN
  res := (
    SELECT 
      PIPE_NAME,
      FILE_NAME,
      LAST_LOAD_TIME,
      STATUS,
      ROW_COUNT,
      ERROR_COUNT
    FROM INFORMATION_SCHEMA.LOAD_HISTORY 
    WHERE LAST_LOAD_TIME >= DATEADD(day, -days_back, CURRENT_TIMESTAMP())
      AND PIPE_NAME IN (
        'PIPE_LOAD_PATIENTS',
        'PIPE_LOAD_DRUGS',
        'PIPE_LOAD_SUPPLIERS',
        'PIPE_LOAD_HOSPITALS',
        'PIPE_LOAD_INVENTORY',
        'PIPE_LOAD_HEALTHCARE_SURVEILLANCE',
        'PIPE_LOAD_PRESCRIPTIONS',
        'PIPE_LOAD_GEOGRAPHIC',
        'PIPE_LOAD_DISEASES'
      )
    ORDER BY LAST_LOAD_TIME DESC
  );
  RETURN TABLE(res);
END;
$$;

-- Procedure to pause all pipes
CREATE OR REPLACE PROCEDURE pause_all_pipes_sp()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
  ALTER PIPE pipe_load_patients SET PIPE_EXECUTION_PAUSED = TRUE;
  ALTER PIPE pipe_load_drugs SET PIPE_EXECUTION_PAUSED = TRUE;
  ALTER PIPE pipe_load_suppliers SET PIPE_EXECUTION_PAUSED = TRUE;
  ALTER PIPE pipe_load_hospitals SET PIPE_EXECUTION_PAUSED = TRUE;
  ALTER PIPE pipe_load_inventory SET PIPE_EXECUTION_PAUSED = TRUE;
  ALTER PIPE pipe_load_healthcare_surveillance SET PIPE_EXECUTION_PAUSED = TRUE;
  ALTER PIPE pipe_load_prescriptions SET PIPE_EXECUTION_PAUSED = TRUE;
  ALTER PIPE pipe_load_geographic SET PIPE_EXECUTION_PAUSED = TRUE;
  ALTER PIPE pipe_load_diseases SET PIPE_EXECUTION_PAUSED = TRUE;
  
  RETURN 'All pipes paused successfully.';
END;
$$;

-- Procedure to resume all pipes
CREATE OR REPLACE PROCEDURE resume_all_pipes_sp()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
  ALTER PIPE pipe_load_patients SET PIPE_EXECUTION_PAUSED = FALSE;
  ALTER PIPE pipe_load_drugs SET PIPE_EXECUTION_PAUSED = FALSE;
  ALTER PIPE pipe_load_suppliers SET PIPE_EXECUTION_PAUSED = FALSE;
  ALTER PIPE pipe_load_hospitals SET PIPE_EXECUTION_PAUSED = FALSE;
  ALTER PIPE pipe_load_inventory SET PIPE_EXECUTION_PAUSED = FALSE;
  ALTER PIPE pipe_load_healthcare_surveillance SET PIPE_EXECUTION_PAUSED = FALSE;
  ALTER PIPE pipe_load_prescriptions SET PIPE_EXECUTION_PAUSED = FALSE;
  ALTER PIPE pipe_load_geographic SET PIPE_EXECUTION_PAUSED = FALSE;
  ALTER PIPE pipe_load_diseases SET PIPE_EXECUTION_PAUSED = FALSE;
  
  RETURN 'All pipes resumed successfully.';
END;
$$;
