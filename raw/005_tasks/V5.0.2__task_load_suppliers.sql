use schema staging;
CREATE OR REPLACE TASK task_load_suppliers
  WAREHOUSE = 'LOAD_WH'
  SCHEDULE = 'USING CRON 30 2 * * * UTC'
AS
BEGIN
  COPY INTO raw_suppliers
  FROM @disease_inv_stage/suppliers.csv
  FILE_FORMAT = csv_ff
  ON_ERROR = 'continue';
  
  INSERT INTO load_audit_log 
  SELECT 
    'raw_suppliers' as table_name,
    COUNT(*) as record_count,
    CURRENT_TIMESTAMP() as load_timestamp
  FROM raw_suppliers;
END;
