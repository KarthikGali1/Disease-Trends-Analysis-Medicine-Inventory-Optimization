create or replace stage disease_inv_stage
URL= 's3://diseasetrendinventory/'
STORAGE_INTEGRATION = disease_inv_int
file_format = RAW_DB_DEV_STAGING.csv_ff;

