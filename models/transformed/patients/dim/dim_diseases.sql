{{ config(
    materialized='table',
    schema='PATIENTS',
    alias='DIM_DISEASE'
) }}

select
    -- Keys
    disease_id,

    -- Basic Info
    disease_name,
    disease_category,

    -- Clinical
    severity_level,
    transmission_type,

    -- Patterns
    seasonal_pattern,
    example_drugs,

    -- Thresholds
    -- outbreak_threshold we dont have,

from {{ ref('stg_diseases') }}
