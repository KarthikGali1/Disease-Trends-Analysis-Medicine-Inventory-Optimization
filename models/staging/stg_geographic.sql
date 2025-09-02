{{ config(materialized = 'view') }}

select
    cast(region_id as string) as region_id,                 -- ensure ID is string
    initcap(trim(state)) as state,                          -- clean + title case
    initcap(trim(city)) as city,                            -- clean + title case
    tier_classification,
    nullif(trim(pincode), '') as pincode,                   -- handle blanks
    nullif(state_population, '')::integer as state_population, -- convert to integer
    nullif(population_density, '')::integer as population_density, -- convert to integer
    district,
    latitude,
    longitude,
    healthcare_facilities_count,
    pharmacy_count

from {{ source('raw', 'RAW_GEOGRAPHIC') }}
