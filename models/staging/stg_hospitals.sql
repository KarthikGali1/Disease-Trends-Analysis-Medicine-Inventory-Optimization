{{ config(materialized = 'view') }}

select
    cast(hospital_id as string) as hospital_id,
    initcap(trim(hospital_name)) as hospital_name,   -- cleaned for readability
    lower(trim(email)) as email,                     -- normalize email
    nullif(bed_capacity, '')::integer as bed_capacity, -- cast to integer
    nullif(established_year, '')::integer as established_year, -- cast to integer
    hospital_location,
    city,
    state,
    region,
    tier,
    pincode,
    hospital_type,
    hospital_tier,
    latitude,
    longitude,
    contact_phone

from {{ source('raw', 'RAW_HOSPITALS') }}
