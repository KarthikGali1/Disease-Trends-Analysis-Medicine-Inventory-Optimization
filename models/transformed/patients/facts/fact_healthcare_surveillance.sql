{{ config(
    materialized='table',
    schema='PATIENTS',
    alias='FACT_HEALTHCARE_SURVEILLANCE'
) }}

with src as (
    select
        -- Foreign Keys (use business IDs as keys for now)
        try_to_date(event_date)        as date_key,
        cast(patient_id  as varchar)   as patient_key,
        cast(hospital_id as varchar)   as hospital_key,
        cast(disease_id  as varchar)   as disease_key,
        cast(region_id   as varchar)   as geographic_key,

        -- Degenerate Dimensions
        cast(surveillance_id as varchar) as surveillance_id,
        /* If available in staging, replace NULL with the column name */
        NULL::varchar                   as admission_batch_id,

        -- Measures - Counts
        coalesce(try_to_number(case_count), 1) as case_count,
        /* Replace NULL with staging column if present */
        NULL::number                             as new_cases,
        NULL::number                             as active_cases,

        -- Measures - Clinical
        try_to_number(body_temperature)  as body_temperature,
        try_to_number(length_of_stay_days) as length_of_stay_days,

        -- Dates (used below for derived metrics too)
        try_to_date(admit_date)     as admit_date,
        try_to_date(discharge_date) as discharge_date,

        -- Attributes
        severity_level,
        /* Replace NULL with staging column if present (e.g., patient_symptoms) */
        NULL::varchar               as patient_symptoms,
        outcome,

        -- Environmental
        weather,
        monsoon_season,
        try_to_number(aqi)                  as aqi,
        /* Replace NULL with staging column if present (e.g., weather_temperature) */
        NULL::number                        as weather_temperature

    from {{ ref('stg_healthcare_surveillance') }}
)

select
    -- Foreign Keys
    date_key,
    patient_key,
    hospital_key,
    disease_key,
    geographic_key,

    -- Degenerate Dimensions
    surveillance_id,
    admission_batch_id,

    -- Measures - Counts
    case_count,
    new_cases,
    active_cases,

    -- Measures - Clinical
    body_temperature,
    length_of_stay_days,

    -- Measures - Derived (kept simple)
    datediff('day', admit_date, date_key)      as days_since_admission,
    datediff('day', admit_date, discharge_date) as treatment_duration_actual,

    -- Attributes
    severity_level,
    patient_symptoms,
    outcome,

    -- Environmental
    weather,
    monsoon_season,
    aqi,
    weather_temperature,

    -- Dates
    admit_date,
    discharge_date

from src;
