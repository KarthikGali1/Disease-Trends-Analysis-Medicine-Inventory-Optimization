USE SCHEMA staging;

-- Step 1: Create a stored procedure with your loading and logging logic
CREATE OR REPLACE PROCEDURE load_geographic_and_log_sp()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
  -- Load geographic data
  COPY INTO raw_geographic
  FROM @disease_inv_stage/geographic_data.csv
  FILE_FORMAT = (FORMAT_NAME = csv_ff) -- Using explicit syntax for clarity
  ON_ERROR = 'continue';

  -- Log the load operation
  INSERT INTO load_audit_log
  SELECT
    'raw_geographic' as table_name,
    COUNT(*) as record_count,
    CURRENT_TIMESTAMP() as load_timestamp
  FROM raw_geographic;

  RETURN 'Geographic data load and log completed successfully.';
END;
$$;

-- Step 2: Create the task to call the stored procedure
CREATE OR REPLACE TASK task_load_geographic
  WAREHOUSE = 'LOAD_WH'
  SCHEDULE = 'USING CRON 40 2 * * * UTC'
AS
  CALL load_geographic_and_log_sp();
