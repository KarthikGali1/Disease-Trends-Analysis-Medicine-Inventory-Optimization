use schema staging;
CREATE OR REPLACE TASK task_load_inventory
  WAREHOUSE = 'LOAD_WH'
  SCHEDULE = 'USING CRON 35 2 * * * UTC'
AS
BEGIN
  COPY INTO raw_inventory
  FROM @disease_inv_stage/inventory.csv
  FILE_FORMAT = csv_ff_inv
  ON_ERROR = 'continue';
  
  INSERT INTO load_audit_log 
  SELECT 
    'raw_inventory' as table_name,
    COUNT(*) as record_count,
    CURRENT_TIMESTAMP() as load_timestamp
  FROM raw_inventory;
END;
