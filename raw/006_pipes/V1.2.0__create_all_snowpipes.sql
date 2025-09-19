-- File: raw/V1.2.0__create_all_snowpipes.sql
-- Description: Create Snowpipes for automatic loading of all data sources
-- Author: Data Engineering Team
-- Date: 2025-01-XX

USE SCHEMA staging;

-- ============================================================================
-- SNOWPIPE FOR DRUGS DATA
-- ============================================================================
CREATE OR REPLACE PIPE pipe_load_drugs
  AUTO_INGEST = TRUE
  AWS_SNS_TOPIC = 'arn:aws:sns:us-east-1:YOUR_ACCOUNT:disease_inv_notifications'
AS
  COPY INTO raw_drugs_with_ids
  FROM @disease_inv_stage/drugs/
  FILE_FORMAT = (FORMAT_NAME = csv_ff)
  PATTERN = '.*drug_with_ids.*\.csv'
  ON_ERROR = 'continue';

-- ============================================================================
-- SNOWPIPE FOR SUPPLIERS DATA
-- ============================================================================
CREATE OR REPLACE PIPE pipe_load_suppliers
  AUTO_INGEST = TRUE
  AWS_SNS_TOPIC = 'arn:aws:sns:us-east-1:YOUR_ACCOUNT:disease_inv_notifications'
AS
  COPY INTO raw_suppliers
  FROM @disease_inv_stage/suppliers/
  FILE_FORMAT = (FORMAT_NAME = csv_ff)
  PATTERN = '.*suppliers.*\.csv'
  ON_ERROR = 'continue';

-- ============================================================================
-- SNOWPIPE FOR HOSPITALS DATA
-- ============================================================================
CREATE OR REPLACE PIPE pipe_load_hospitals
  AUTO_INGEST = TRUE
  AWS_SNS_TOPIC = 'arn:aws:sns:us-east-1:YOUR_ACCOUNT:disease_inv_notifications'
AS
  COPY INTO raw_hospitals
  FROM @disease_inv_stage/hospitals/
  FILE_FORMAT = (FORMAT_NAME = csv_ff)
  PATTERN = '.*hospitals_data.*\.csv'
  ON_ERROR = 'continue';

-- ============================================================================
-- SNOWPIPE FOR INVENTORY DATA
-- ============================================================================
CREATE OR REPLACE PIPE pipe_load_inventory
  AUTO_INGEST = TRUE
  AWS_SNS_TOPIC = 'arn:aws:sns:us-east-1:YOUR_ACCOUNT:disease_inv_notifications'
AS
  COPY INTO raw_inventory
  FROM @disease_inv_stage/inventory/
  FILE_FORMAT = (FORMAT_NAME = csv_ff_inv)
  PATTERN = '.*inventory.*\.csv'
  ON_ERROR = 'continue';

-- ============================================================================
-- SNOWPIPE FOR HEALTHCARE SURVEILLANCE DATA
-- ============================================================================
CREATE OR REPLACE PIPE pipe_load_healthcare_surveillance
  AUTO_INGEST = TRUE
  AWS_SNS_TOPIC = 'arn:aws:sns:us-east-1:YOUR_ACCOUNT:disease_inv_notifications'
AS
  COPY INTO raw_healthcare_surveillance
  FROM @disease_inv_stage/surveillance/
  FILE_FORMAT = (FORMAT_NAME = csv_ff_fixed)
  PATTERN = '.*healthcare_surveillance.*\.csv'
  ON_ERROR = 'continue';

-- ============================================================================
-- SNOWPIPE FOR PRESCRIPTIONS DATA
-- ============================================================================
CREATE OR REPLACE PIPE pipe_load_prescriptions
  AUTO_INGEST = TRUE
  AWS_SNS_TOPIC = 'arn:aws:sns:us-east-1:YOUR_ACCOUNT:disease_inv_notifications'
AS
  COPY INTO raw_prescriptions
  FROM @disease_inv_stage/prescriptions/
  FILE_FORMAT = (FORMAT_NAME = csv_ff)
  PATTERN = '.*prescriptions.*\.csv'
  ON_ERROR = 'continue';

-- ============================================================================
-- SNOWPIPE FOR GEOGRAPHIC DATA
-- ============================================================================
CREATE OR REPLACE PIPE pipe_load_geographic
  AUTO_INGEST = TRUE
  AWS_SNS_TOPIC = 'arn:aws:sns:us-east-1:YOUR_ACCOUNT:disease_inv_notifications'
AS
  COPY INTO raw_geographic
  FROM @disease_inv_stage/geographic/
  FILE_FORMAT = (FORMAT_NAME = csv_ff)
  PATTERN = '.*geographic_data.*\.csv'
  ON_ERROR = 'continue';

-- ============================================================================
-- SNOWPIPE FOR DISEASES DATA
-- ============================================================================
CREATE OR REPLACE PIPE pipe_load_diseases
  AUTO_INGEST = TRUE
  AWS_SNS_TOPIC = 'arn:aws:sns:us-east-1:YOUR_ACCOUNT:disease_inv_notifications'
AS
  COPY INTO raw_diseases_with_ids
  FROM @disease_inv_stage/diseases/
  FILE_FORMAT = (FORMAT_NAME = csv_ff)
  PATTERN = '.*disease_with_ids.*\.csv'
  ON_ERROR = 'continue';
