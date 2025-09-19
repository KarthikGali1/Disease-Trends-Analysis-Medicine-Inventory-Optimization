USE SCHEMA staging;

-- Step 1: Create a stored procedure with your loading and logging logic
CREATE OR REPLACE PROCEDURE load_prescriptions_and_log_sp()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
  -- Load prescriptions data
  COPY INTO raw_prescriptions
  FROM @disease_inv_stage/prescriptions.csv
  FILE_FORMAT = (FORMAT_NAME = csv_ff)
  ON_ERROR = 'continue';

  -- Log the load operation
  INSERT INTO load_audit_log
  SELECT
    'raw_prescriptions' as table_name,
    COUNT(*) as record_count,
    CURRENT_TIMESTAMP() as load_timestamp
  FROM raw_prescriptions;

  RETURN 'Prescriptions load and log completed successfully.';
END;
$$;

-- Step 2: Create the task to call the stored procedure
CREATE OR REPLACE TASK task_load_prescriptions
  WAREHOUSE = 'LOAD_WH'
  SCHEDULE = 'USING CRON 20 2 * * * UTC'
AS
  CALL load_prescriptions_and_log_sp();
