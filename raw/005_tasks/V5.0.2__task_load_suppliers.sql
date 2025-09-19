USE SCHEMA staging;

-- Step 1: Create a stored procedure containing your multi-statement logic
CREATE OR REPLACE PROCEDURE load_suppliers_and_log_sp()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
  -- Load suppliers data
  COPY INTO raw_suppliers
  FROM @disease_inv_stage/suppliers.csv
  FILE_FORMAT = (FORMAT_NAME = csv_ff) -- Using explicit syntax for clarity
  ON_ERROR = 'continue';

  -- Log the load operation
  INSERT INTO load_audit_log
  SELECT
    'raw_suppliers' as table_name,
    COUNT(*) as record_count,
    CURRENT_TIMESTAMP() as load_timestamp
  FROM raw_suppliers;

  RETURN 'Suppliers load and log completed successfully.';
END;
$$;

-- Step 2: Create the task to call the stored procedure
CREATE OR REPLACE TASK task_load_suppliers
  WAREHOUSE = 'LOAD_WH'
  SCHEDULE = 'USING CRON 30 2 * * * UTC'
AS
  CALL load_suppliers_and_log_sp();
