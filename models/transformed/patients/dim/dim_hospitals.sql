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
    case 
        when lower(tier) = 'tier 1' then 1
        when lower(tier) = 'tier 2' then 2
        when lower(tier) = 'tier 3' then 3
        else null
    end as tier_numeric,
    distance_from_major_city,

    -- Audit
    effective_date,
    expiry_date,
    case
        when expiry_date is null or expiry_date >= current_date then true
        else false
    end as is_current

from {{ ref('stg_hospitals') }}
