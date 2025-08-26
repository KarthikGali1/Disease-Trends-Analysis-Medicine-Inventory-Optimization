{{ config(materialized = 'view') }}

select
    cast(surveillance_id as string) as surveillance_id,
    cast(patient_id as string) as patient_id,
    initcap(trim(patient_name)) as patient_name,      
    cast(hospital_id as string) as hospital_id,
    cast(disease_id as string) as disease_id,
    cast(region_id as string) as region_id,
    date,
    admit_date,
    discharge_date,
    nullif(length_of_stay_days, '')::integer as length_of_stay_days,
    nullif(patient_age, '')::integer as patient_age,
    case lower(trim(patient_gender))
        when 'm' then 'Male'
        when 'f' then 'Female'
        else 'Other'
    end as patient_gender,
    try_to_number(nullif(trim(case_count), ''))::integer as case_count,
    initcap(trim(severity_level)) as severity_level, -- title case for consistency
    patient_symptoms,
    hospital_name,
    hospital_location,
    disease_name,
    state,
    city,
    body_temperature,
    weather,
    monsoon_season,
    aqi,
    outcome

from {{ source('raw', 'RAW_HEALTHCARE_SURVEILLANCE') }}
