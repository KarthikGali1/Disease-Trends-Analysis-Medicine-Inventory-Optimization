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
    population_density as population_per_sqkm,
    case 
        when population_density = 0 or population_density is null then null
        else state_population / population_density
    end as geographic_area

from {{ ref('stg_geographic') }}
