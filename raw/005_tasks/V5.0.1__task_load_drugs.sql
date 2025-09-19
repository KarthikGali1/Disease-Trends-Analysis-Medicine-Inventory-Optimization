USE SCHEMA staging;

-- Step 1: Create a stored procedure with your loading and logging logic
CREATE OR REPLACE PROCEDURE load_drugs_and_log_sp()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
  -- Load drugs data
  COPY INTO raw_drugs_with_ids
  FROM @disease_inv_stage/drug_with_ids.csv
  FILE_FORMAT = (FORMAT_NAME = csv_ff)
  ON_ERROR = 'continue';

  -- Log validation
  INSERT INTO load_audit_log
  SELECT
    'raw_drugs_with_ids' as table_name,
    COUNT(*) as record_count,
    CURRENT_TIMESTAMP() as load_timestamp
  FROM raw_drugs_with_ids;

  RETURN 'Drug load and log completed successfully.';
END;
$$;

-- Step 2: Create the task to call the stored procedure
CREATE OR REPLACE TASK task_load_drugs
  WAREHOUSE = 'LOAD_WH'
  SCHEDULE = 'USING CRON 5 2 * * * UTC' -- 5 minutes after patients
AS
  CALL load_drugs_and_log_sp();
