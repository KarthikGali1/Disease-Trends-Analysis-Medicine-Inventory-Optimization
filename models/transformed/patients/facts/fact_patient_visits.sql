{{ config(
    materialized='table',
    schema='PATIENTS',
    alias='FACT_PATIENT_VISITS'
) }}

with visits as (
    select *
    from {{ ref('stg_healthcare_surveillance') }}
)

select
    v.surveillance_id,
    v.patient_id,
    v.hospital_id,
    v.disease_id,
    v.region_id,
    v.admit_date,
    v.discharge_date,
    v.length_of_stay_days,
    v.patient_age,
    v.patient_gender,
    v.case_count,
    v.severity_level,
    v.outcome
from visits v
