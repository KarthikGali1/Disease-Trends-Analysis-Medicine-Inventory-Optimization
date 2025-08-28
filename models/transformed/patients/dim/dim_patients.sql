{{ config(
    materialized='table',
    schema='PATIENTS',
    alias='DIM_PATIENTS'
) }}

select
    -- Keys
    cast(patient_id as varchar) as patient_id,

    -- Demographics
    initcap(trim(patient_name)) as patient_name,
    try_to_number(patient_age) as patient_age,
    case lower(trim(patient_gender))
        when 'm' then 'Male'
        when 'f' then 'Female'
        else 'Other'
    end as patient_gender,
    upper(trim(blood_group)) as blood_group,

    -- Contact Info
    trim(contact_phone) as contact_phone,
    lower(trim(email)) as email,
    initcap(trim(address)) as address,
    initcap(trim(city)) as city,
    initcap(trim(state)) as state,
    trim(pincode) as pincode,

    -- Emergency
    trim(emergency_contact) as emergency_contact,

    -- Insurance
    initcap(trim(insurance_provider)) as insurance_provider,
    initcap(trim(govt_scheme)) as govt_scheme,

    -- Derived Demographics
    case
        when try_to_number(patient_age) < 18 then 'Child'
        when try_to_number(patient_age) between 18 and 59 then 'Adult'
        else 'Senior'
    end as age_group,

    -- Audit
    try_to_date(registration_date) as registration_date,
    --effective_date,expiry_date,is_current

from {{ ref('stg_patients') }}
