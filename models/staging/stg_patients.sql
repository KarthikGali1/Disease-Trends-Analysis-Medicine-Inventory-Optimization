{{ config(materialized = 'view') }}

select
    -- Transformed Columns
    cast(patient_id as string) as patient_id,   -- ensure ID is string
    initcap(trim(patient_name)) as patient_name,  -- clean + uppercase name
    case lower(trim(patient_gender))
        when 'm' then 'Male'
        when 'f' then 'Female'
        else 'Other'
    end as patient_gender,                      -- normalize gender
    nullif(patient_age, '')::integer as patient_age, -- convert to integer
    upper(blood_group) as blood_group,          -- standardize blood group
    lower(email) as email,                      -- lowercase emails

    -- Pass-through Columns (no transformation applied)
    contact_phone,
    address,
    city,
    state,
    pincode,
    emergency_contact,
    insurance_provider,
    govt_scheme,
    registration_date

from {{ source('raw', 'RAW_PATIENTS') }}
