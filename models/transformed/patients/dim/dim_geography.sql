{{ config(
    materialized='table',
    schema='PATIENTS',
    alias='DIM_GEOGRAPHIC'
) }}

select
    -- Keys
    region_id,

    -- Administrative
    state,
    city,
    tier_classification,
    district,
    pincode,

    -- Coordinates
    latitude,
    longitude,

    -- Demographics
    state_population,
    population_density,

    -- Infrastructure
    healthcare_facilities_count,
    pharmacy_count,

    -- Derived Metrics
    population_per_sqkm,
    geographic_area,

    -- Audit
    effective_date,
    expiry_date,
    case
        when expiry_date is null or expiry_date >= current_date then true
        else false
    end as is_current

from {{ ref('stg_geographic') }}
