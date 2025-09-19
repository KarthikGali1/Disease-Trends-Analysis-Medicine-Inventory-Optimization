use schema staging;
create or replace file format csv_ff_inv
  type = 'CSV'
  field_delimiter = ','
  skip_header = 1
  null_if = ('NULL', 'null', '########')  -- treat Excel overflow as NULL
  empty_field_as_null = true
  field_optionally_enclosed_by = '"'
  trim_space = true
  date_format = 'MM/DD/YYYY'              -- match your data
  timestamp_format = 'MM/DD/YYYY HH24:MI:SS'
  encoding = 'UTF8'
  error_on_column_count_mismatch = false;
