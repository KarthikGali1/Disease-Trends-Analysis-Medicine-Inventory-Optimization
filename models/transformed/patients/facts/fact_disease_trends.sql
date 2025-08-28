{{ config(
    materialized='table',
    schema='PATIENTS',
    alias='FACT_DISEASE_TRENDS'
) }}

with surveillance as (
    select *
    from {{ ref('stg_healthcare_surveillance') }}
)

select
    s.disease_id,
    s.region_id,
    s.date as trend_date,
    sum(s.case_count) as total_cases,
    avg(s.length_of_stay_days) as avg_length_of_stay
from surveillance s
group by s.disease_id, s.region_id, s.date
