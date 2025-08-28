{{ config(
    materialized='table',
    schema='PATIENTS',
    alias='FACT_GEOGRAPHIC_HOTSPOTS'
) }}

with cases as (
    select
        h.region_id,
        g.state,
        g.city,
        g.latitude,
        g.longitude,
        g.population_density,
        g.state_population,
        g.healthcare_facilities_count,
        g.pharmacy_count,
        sum(h.case_count) as total_cases,
        count(distinct h.patient_id) as total_patients,
        max(h.date) as latest_date
    from {{ ref('stg_healthcare_surveillance') }} h
    join {{ ref('stg_geographic') }} g
      on h.region_id = g.region_id
    group by 1,2,3,4,5,6,7,8,9
)

select
    c.*,
    (c.total_cases / nullif(c.population_density,0)) * 1000 as cases_per_1k_density,

    -- Simple hotspot scoring (placeholder before Cortex AI ML integration)
    case
      when (c.total_cases / nullif(c.population_density,0)) * 1000 > 50 then 'Critical'
      when (c.total_cases / nullif(c.population_density,0)) * 1000 between 20 and 50 then 'Warning'
      else 'Normal'
    end as hotspot_risk_level
from cases c
