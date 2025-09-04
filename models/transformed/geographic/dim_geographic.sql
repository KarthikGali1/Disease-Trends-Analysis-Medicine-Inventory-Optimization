SELECT DISTINCT
    region_id::STRING AS region_id,
    state::STRING AS state,
    city::STRING AS city,
    tier_classification::STRING AS tier_classification,
    district::STRING AS district,
    pincode::STRING AS pincode,
    latitude::STRING AS latitude,
    longitude::STRING AS longitude,
    TRY_TO_NUMBER(state_population) AS state_population,
    TRY_TO_NUMBER(population_density) AS population_density,
    TRY_TO_NUMBER(healthcare_facilities_count) AS healthcare_facilities_count,
    TRY_TO_NUMBER(pharmacy_count) AS pharmacy_count
FROM --RAW_GEOGRAPHIC
    {{ source('raw', 'RAW_GEOGRAPHIC') }}