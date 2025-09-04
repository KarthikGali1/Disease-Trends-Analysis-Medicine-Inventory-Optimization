SELECT
    rhs.surveillance_id::STRING AS surveillance_id,
    rhs.patient_id::STRING AS patient_id,
    rhs.hospital_id::STRING AS hospital_id,
    rhs.disease_id::STRING AS disease_id,
    rhs.region_id::STRING AS region_id,
    TRY_TO_NUMBER(rhs.case_count, 10, 0) AS case_count,
    rhs.severity_level::STRING AS severity_level,
    TRY_TO_DATE(rhs.admit_date) AS admit_date,
    TRY_TO_DATE(rhs.discharge_date) AS discharge_date,
    TRY_TO_NUMBER(rhs.length_of_stay_days, 10, 0) AS length_of_stay_days,
    TRY_TO_NUMBER(rhs.body_temperature, 5, 2) AS body_temperature,
    rhs.weather::STRING AS weather,
    rhs.outcome::STRING AS outcome,
    -- Calculated analytics columns with explicits casting
    (CASE
        WHEN TRY_TO_DATE(rhs.discharge_date) IS NULL THEN TRUE
        ELSE FALSE
    END)::BOOLEAN AS is_active_case,
    (CASE
        WHEN MONTH(TRY_TO_DATE(rhs.admit_date)) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH(TRY_TO_DATE(rhs.admit_date)) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(TRY_TO_DATE(rhs.admit_date)) IN (6, 7, 8) THEN 'Summer'
        WHEN MONTH(TRY_TO_DATE(rhs.admit_date)) IN (9, 10, 11) THEN 'Fall'
        ELSE NULL
    END)::STRING AS season,
    YEAR(TRY_TO_DATE(rhs.admit_date))::NUMBER AS admission_year,
    MONTH(TRY_TO_DATE(rhs.admit_date))::NUMBER AS admission_month,
    WEEKOFYEAR(TRY_TO_DATE(rhs.admit_date))::NUMBER AS admission_week
FROM
    {{ source('raw', 'RAW_HEALTHCARE_SURVEILLANCE') }} AS rhs
WHERE
    rhs.surveillance_id IS NOT NULL





