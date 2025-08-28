{{ config(
    materialized='table',
    schema='PATIENTS',
    alias='DIM_GEOGRAPHY'
) }}

select
    region_id,
    state,
    city,
    tier_classification,
    pincode,
    state_population,
    population_density,
    district,
    latitude,
    longitude,
    healthcare_facilities_count,
    pharmacy_count
from {{ ref('stg_geographic') }}
