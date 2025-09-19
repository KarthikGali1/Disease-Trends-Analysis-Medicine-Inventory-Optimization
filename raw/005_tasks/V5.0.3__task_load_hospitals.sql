use schema staging;
CREATE OR REPLACE TASK task_load_hospitals
  WAREHOUSE = 'LOAD_WH'
  SCHEDULE = 'USING CRON 15 2 * * * UTC'
AS
BEGIN
  COPY INTO raw_hospitals
  FROM @disease_inv_stage/hospitals_data.csv
  FILE_FORMAT = (FORMAT_NAME = csv_ff)
  ON_ERROR = 'continue';
  
  INSERT INTO load_audit_log 
  SELECT 
    'raw_hospitals' as table_name,
    COUNT(*) as record_count,
    CURRENT_TIMESTAMP() as load_timestamp
  FROM raw_hospitals;
END;
