USE SCHEMA staging;

-- Step 1: Create a stored procedure with your loading and logging logic
CREATE OR REPLACE PROCEDURE load_healthcare_surveillance_and_log_sp()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
  -- Load healthcare surveillance data
  COPY INTO raw_healthcare_surveillance
  FROM @disease_inv_stage/healthcare_surveillance.csv
  FILE_FORMAT = (FORMAT_NAME = csv_ff_fixed) -- Using explicit syntax for clarity
  ON_ERROR = 'continue';

  -- Log the load operation
  INSERT INTO load_audit_log
  SELECT
    'raw_healthcare_surveillance' as table_name,
    COUNT(*) as record_count,
    CURRENT_TIMESTAMP() as load_timestamp
  FROM raw_healthcare_surveillance;

  RETURN 'Healthcare surveillance load and log completed successfully.';
END;
$$;

-- Step 2: Create the task to call the stored procedure
CREATE OR REPLACE TASK task_load_healthcare_surveillance
  WAREHOUSE = 'LOAD_WH'
  SCHEDULE = 'USING CRON 25 2 * * * UTC'
AS
  CALL load_healthcare_surveillance_and_log_sp();
