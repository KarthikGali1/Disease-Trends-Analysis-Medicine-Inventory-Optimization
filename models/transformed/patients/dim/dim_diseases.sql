{{ config(
    materialized='table',
    schema='PATIENTS',
    alias='DIM_DISEASES'
) }}

select
    disease_id,
    disease_name,
    disease_category,
    severity_level,
    transmission_type,
    seasonal_pattern,
    example_drugs
from {{ ref('stg_diseases') }}
