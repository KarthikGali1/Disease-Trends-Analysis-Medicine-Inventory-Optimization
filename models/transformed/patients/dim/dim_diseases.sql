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
    severity_levels,
    transmission_type,

    -- Patterns
    seasonal_pattern,
    example_drugs,

    -- Thresholds
    outbreak_threshold,

    -- Audit
    effective_date,
    expiry_date,
    case
        when expiry_date is null or expiry_date >= current_date then true
        else false
    end as is_current

from {{ ref('stg_diseases') }}
