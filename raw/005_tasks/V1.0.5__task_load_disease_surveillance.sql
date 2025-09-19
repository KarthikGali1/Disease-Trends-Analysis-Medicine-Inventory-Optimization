CREATE OR REPLACE TASK task_load_healthcare_surveillance
  WAREHOUSE = 'LOAD_WH'
  SCHEDULE = 'USING CRON 25 2 * * * UTC'
AS
BEGIN
  COPY INTO raw_healthcare_surveillance
  FROM @disease_inv_stage/healthcare_surveillance.csv
  FILE_FORMAT = csv_ff_fixed
  ON_ERROR = 'continue';
  
  INSERT INTO load_audit_log 
  SELECT 
    'raw_healthcare_surveillance' as table_name,
    COUNT(*) as record_count,
    CURRENT_TIMESTAMP() as load_timestamp
  FROM raw_healthcare_surveillance;
END;
