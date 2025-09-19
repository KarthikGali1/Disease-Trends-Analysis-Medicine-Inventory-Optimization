CREATE OR REPLACE TABLE load_audit_log (
    table_name STRING,
    record_count NUMBER,
    load_timestamp TIMESTAMP_NTZ,
    load_status STRING DEFAULT 'SUCCESS'
);
