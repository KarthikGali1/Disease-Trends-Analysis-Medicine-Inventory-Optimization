USE SCHEMA staging;

-- Step 1: Create a stored procedure with your loading and logging logic
CREATE OR REPLACE PROCEDURE load_hospitals_and_log_sp()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
  -- Load hospitals data
  COPY INTO raw_hospitals
  FROM @disease_inv_stage/hospitals_data.csv
  FILE_FORMAT = (FORMAT_NAME = csv_ff)
  ON_ERROR = 'continue';

  -- Log the load operation
  INSERT INTO load_audit_log
  SELECT
    'raw_hospitals' as table_name,
    COUNT(*) as record_count,
    CURRENT_TIMESTAMP() as load_timestamp
  FROM raw_hospitals;

  RETURN 'Hospitals load and log completed successfully.';
END;
$$;

-- Step 2: Create the task to call the stored procedure
CREATE OR REPLACE TASK task_load_hospitals
  WAREHOUSE = 'LOAD_WH'
  SCHEDULE = 'USING CRON 15 2 * * * UTC'
AS
  CALL load_hospitals_and_log_sp();
