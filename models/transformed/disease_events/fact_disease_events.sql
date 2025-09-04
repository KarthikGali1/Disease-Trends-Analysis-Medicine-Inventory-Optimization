SELECT
    rhs.surveillance_id::STRING AS surveillance_id,
    rhs.hospital_id::STRING AS hospital_id,
    rhs.disease_id::STRING AS disease_id,
    rhs.region_id::STRING AS region_id,
    TRY_TO_DATE(rhs.admit_date) AS event_date,
    TRY_TO_NUMBER(rhs.case_count) AS case_count,
    MD5(TRIM(UPPER(rhs.severity_level)))::STRING AS severity_code,
    rhs.weather::STRING AS weather,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS created_date
FROM --RAW_HEALTHCARE_SURVEILLANCE
    {{ source('raw', 'RAW_HEALTHCARE_SURVEILLANCE') }} AS rhs
