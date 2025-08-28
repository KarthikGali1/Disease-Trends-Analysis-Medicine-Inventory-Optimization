{{ config(
    materialized='table',
    schema='PATIENTS',
    alias='DIM_PATIENTS'
) }}

select
    patient_id,
    patient_name,
    patient_gender,
    patient_age,
    blood_group,
    email,
    city,
    state,
    pincode,
    address,
    emergency_contact,
    insurance_provider,
    govt_scheme,
    registration_date
from {{ ref('stg_patients') }}
