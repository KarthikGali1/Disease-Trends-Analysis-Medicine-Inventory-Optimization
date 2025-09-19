use schema staging;
CREATE OR REPLACE TASK task_load_geographic
  WAREHOUSE = 'LOAD_WH'
  SCHEDULE = 'USING CRON 40 2 * * * UTC'
AS
BEGIN
  COPY INTO raw_geographic
  FROM @disease_inv_stage/geographic_data.csv
  FILE_FORMAT = csv_ff
  ON_ERROR = 'continue';
  
  INSERT INTO load_audit_log 
  SELECT 
    'raw_geographic' as table_name,
    COUNT(*) as record_count,
    CURRENT_TIMESTAMP() as load_timestamp
  FROM raw_geographic;
END;
