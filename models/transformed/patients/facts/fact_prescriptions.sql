{{ config(
    materialized='table',
    schema='PATIENTS',
    alias='FACT_PRESCRIPTIONS'
) }}

with prescriptions as (
    select *
    from {{ ref('stg_prescriptions') }}
),
patients as (
    select patient_id, patient_name, patient_gender, patient_age
    from {{ ref('dim_patients') }}
),
diseases as (
    select disease_id, disease_name, severity_level
    from {{ ref('dim_diseases') }}
),
hospitals as (
    select hospital_id, hospital_name, city, state
    from {{ ref('dim_hospitals') }}
)

select
    pr.prescription_id,
    pr.patient_id,
    pa.patient_name,
    pa.patient_gender,
    pa.patient_age,
    pr.medicine_name,
    pr.disease_id,
    d.disease_name,
    d.severity_level,
    pr.hospital_id,
    h.hospital_name,
    h.city as hospital_city,
    h.state as hospital_state,
    pr.transaction_date,
    pr.quantity_prescribed,
    pr.quantity_dispensed,
    pr.treatment_duration_days,
    pr.daily_dose_frequency,
    pr.unit_price,
    pr.total_amount
from prescriptions pr
left join patients pa on pr.patient_id = pa.patient_id
left join diseases d on pr.disease_id = d.disease_id
left join hospitals h on pr.hospital_id = h.hospital_id
