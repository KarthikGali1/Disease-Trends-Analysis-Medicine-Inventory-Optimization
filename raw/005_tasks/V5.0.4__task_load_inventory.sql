USE SCHEMA staging;

-- Step 1: Create a stored procedure with your loading and logging logic
CREATE OR REPLACE PROCEDURE load_inventory_and_log_sp()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
  -- Load inventory data
  COPY INTO raw_inventory
  FROM @disease_inv_stage/inventory.csv
  FILE_FORMAT = (FORMAT_NAME = csv_ff_inv) -- Using explicit syntax for clarity
  ON_ERROR = 'continue';

  -- Log the load operation
  INSERT INTO load_audit_log
  SELECT
    'raw_inventory' as table_name,
    COUNT(*) as record_count,
    CURRENT_TIMESTAMP() as load_timestamp
  FROM raw_inventory;

  RETURN 'Inventory load and log completed successfully.';
END;
$$;

-- Step 2: Create the task to call the stored procedure
CREATE OR REPLACE TASK task_load_inventory
  WAREHOUSE = 'LOAD_WH'
  SCHEDULE = 'USING CRON 35 2 * * * UTC'
AS
  CALL load_inventory_and_log_sp();
