CREATE OR REPLACE TASK task_load_prescriptions
  WAREHOUSE = 'LOAD_WH'
  SCHEDULE = 'USING CRON 20 2 * * * UTC'
AS
BEGIN
  COPY INTO raw_prescriptions
  FROM @disease_inv_stage/prescriptions.csv
  FILE_FORMAT = (FORMAT_NAME = csv_ff)
  ON_ERROR = 'continue';
  
  INSERT INTO load_audit_log 
  SELECT 
    'raw_prescriptions' as table_name,
    COUNT(*) as record_count,
    CURRENT_TIMESTAMP() as load_timestamp
  FROM raw_prescriptions;
END;
