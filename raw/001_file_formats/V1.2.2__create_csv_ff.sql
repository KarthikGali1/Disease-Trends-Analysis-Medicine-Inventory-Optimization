use schema staging;
create or replace file format csv_ff
  type = 'CSV'
  field_delimiter = ','
  skip_header = 1
  null_if = ('NULL', 'null')
  empty_field_as_null = true
  field_optionally_enclosed_by = '"'
  trim_space = true
  date_format = 'MM/DD/YYYY'     
  timestamp_format = 'YYYY-MM-DD HH24:MI:SS'
  encoding = 'UTF8'
  error_on_column_count_mismatch = false;  
