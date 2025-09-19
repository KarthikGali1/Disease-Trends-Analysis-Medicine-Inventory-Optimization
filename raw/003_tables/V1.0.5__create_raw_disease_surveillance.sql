CREATE OR REPLACE TABLE raw_healthcare_surveillance (
    surveillance_id STRING,
    patient_id STRING,
    patient_name STRING,
    hospital_id STRING,
    disease_id STRING,
    region_id STRING,
    date DATE,
    admit_date DATE,
    discharge_date DATE,
    length_of_stay_days NUMBER,
    patient_age NUMBER,
    patient_gender STRING,
    patient_symptoms STRING,
    hospital_name STRING,
    hospital_location STRING,
    disease_name STRING,
    state STRING,
    city STRING,
    case_count NUMBER,
    severity_level STRING,
    body_temperature FLOAT,
    weather STRING,
    monsoon_season STRING,
    aqi NUMBER,
    outcome STRING
);


