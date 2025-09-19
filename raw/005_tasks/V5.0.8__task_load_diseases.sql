CREATE OR REPLACE TASK task_load_diseases
  WAREHOUSE = 'LOAD_WH'
  SCHEDULE = 'USING CRON 10 2 * * * UTC'
AS
BEGIN
  COPY INTO raw_diseases_with_ids
  FROM @disease_inv_stage/disease_with_ids.csv
  FILE_FORMAT = (FORMAT_NAME = csv_ff)
  ON_ERROR = 'continue';
  
  INSERT INTO load_audit_log 
  SELECT 
    'raw_diseases_with_ids' as table_name,
    COUNT(*) as record_count,
    CURRENT_TIMESTAMP() as load_timestamp
  FROM raw_diseases_with_ids;
END;
