{{ config(
    materialized='table',
    schema='PATIENTS',
    alias='DIM_HOSPITALS'
) }}

select
    -- Keys
    hospital_id,

    -- Basic Info
    hospital_name,
    hospital_location,
    city,
    state,
    region,

    -- Classification
    tier,
    pincode,
    hospital_type,
    hospital_tier,

    -- Infrastructure
    bed_capacity,
    established_year,

    -- Geographic
    latitude,
    longitude,

    -- Contact
    contact_phone,
    email,

    -- Derived Geographic
    --tier_numeric,
    --distance_from_major_city,

from {{ ref('stg_hospitals') }}
