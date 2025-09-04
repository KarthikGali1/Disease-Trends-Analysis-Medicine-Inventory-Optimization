SELECT
    rhs.surveillance_id::STRING AS case_id,
    rhs.patient_id::STRING AS patient_id,
    rhs.hospital_id::STRING AS hospital_id,
    rhs.disease_id::STRING AS disease_id,
    TRY_TO_DATE(rhs.admit_date) AS admit_date,
    TRY_TO_DATE(rhs.discharge_date) AS discharge_date,
    TRY_TO_NUMBER(rhs.length_of_stay_days) AS length_of_stay_days,
    TRY_TO_NUMBER(rhs.body_temperature, 5, 2) AS body_temperature,
    rhs.outcome::STRING AS outcome,
    MD5(TRIM(UPPER(rhs.severity_level)))::STRING AS severity_code,
    -- Calculated analytics columns with explicit casting and aliase
    (CASE
        WHEN rhs.discharge_date IS NULL THEN TRUE
        ELSE FALSE
    END)::BOOLEAN AS is_active_case,
    (CASE
        WHEN MONTH(TRY_TO_DATE(rhs.admit_date)) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH(TRY_TO_DATE(rhs.admit_date)) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(TRY_TO_DATE(rhs.admit_date)) IN (6, 7, 8) THEN 'Summer'
        WHEN MONTH(TRY_TO_DATE(rhs.admit_date)) IN (9, 10, 11) THEN 'Fall'
    END)::STRING AS season,
    YEAR(TRY_TO_DATE(rhs.admit_date))::NUMBER AS admission_year,
    MONTH(TRY_TO_DATE(rhs.admit_date))::NUMBER AS admission_month,
    WEEKOFYEAR(TRY_TO_DATE(rhs.admit_date))::NUMBER AS admission_week,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS created_date
FROM
    {{ source('raw', 'RAW_HEALTHCARE_SURVEILLANCE') }} AS rhs