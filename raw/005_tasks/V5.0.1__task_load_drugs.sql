use schema staging;
CREATE OR REPLACE TASK task_load_drugs
  WAREHOUSE = 'LOAD_WH'
  SCHEDULE = 'USING CRON 5 2 * * * UTC'  -- 5 minutes after patients
AS
BEGIN
  COPY INTO raw_drugs_with_ids
  FROM @disease_inv_stage/drug_with_ids.csv
  FILE_FORMAT = (FORMAT_NAME = csv_ff)
  ON_ERROR = 'continue';
  
  -- Validation
  INSERT INTO load_audit_log 
  SELECT 
    'raw_drugs_with_ids' as table_name,
    COUNT(*) as record_count,
    CURRENT_TIMESTAMP() as load_timestamp
  FROM raw_drugs_with_ids;
END;
