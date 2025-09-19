use schema staging;
CREATE OR REPLACE TASK task_load_patients
  WAREHOUSE = 'LOAD_WH'  -- Replace with your warehouse
  SCHEDULE = 'USING CRON 0 2 * * * UTC'  -- Daily at 2 AM UTC
AS
BEGIN
 
  
  -- Load patients data
  COPY INTO raw_patients
  FROM @disease_inv_stage/patients.csv
  FILE_FORMAT = (FORMAT_NAME = csv_ff)
  ON_ERROR = 'continue';
  
  -- Log validation
  INSERT INTO load_audit_log 
  SELECT 
    'raw_patients' as table_name,
    COUNT(*) as record_count,
    CURRENT_TIMESTAMP() as load_timestamp
  FROM raw_patients;
END;
