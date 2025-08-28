{{ config(
    materialized='table',
    schema='PATIENTS',
    alias='FACT_DISEASE_SURVEILLANCE'
) }}

with src as (
    select * from {{ ref('stg_healthcare_surveillance') }}
),

daily_trends as (
    select
        date,
        count(*) as daily_cases,
        sum(case when outcome = 'Death' then 1 else 0 end) as daily_deaths,
        sum(case when outcome = 'Recovered' then 1 else 0 end) as daily_recoveries,
        avg(length_of_stay_days) as avg_length_of_stay,

        -- previous day's cases
        lag(count(*)) over (order by date) as previous_day_cases,

        -- daily percentage change
        round(
            ((count(*) - lag(count(*)) over (order by date))
             / nullif(lag(count(*)) over (order by date), 0)) * 100, 2
        ) as daily_change_pct,

        -- case fatality rate and recovery rate
        round(sum(case when outcome = 'Death' then 1 else 0 end) * 1.0 / nullif(count(*), 0), 3)
            as case_fatality_rate,
        round(sum(case when outcome = 'Recovered' then 1 else 0 end) * 1.0 / nullif(count(*), 0), 3)
            as recovery_rate

    from src
    group by date
)

select
    s.surveillance_id,
    s.patient_id,
    s.hospital_id,
    s.disease_id,
    s.region_id,
    s.date,
    s.admit_date,
    s.discharge_date,
    s.length_of_stay_days,
    s.patient_age,
    s.patient_gender,
    s.disease_name,
    s.severity_level,
    s.case_count,
    s.outcome,
    s.body_temperature,
    s.weather,
    s.aqi,
    s.monsoon_season,

    -- aggregated daily metrics
    t.daily_cases,
    t.previous_day_cases,
    t.daily_change_pct,
    t.case_fatality_rate,
    t.recovery_rate,
    t.avg_length_of_stay

from src s
join daily_trends t
    on s.date = t.date
