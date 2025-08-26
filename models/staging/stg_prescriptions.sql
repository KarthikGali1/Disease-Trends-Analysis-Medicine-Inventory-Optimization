{{ config(materialized='view') }}

select
    cast(prescription_id as string) as prescription_id,       -- ensure string
    initcap(trim(patient_name)) as patient_name,              -- clean title case
    initcap(trim(medicine_name)) as medicine_name,            -- clean title case
    trim(payment_method) as payment_method,            -- normalize text
    initcap(trim(prescription_status)) as prescription_status,-- standardized status
    transaction_id,
    patient_id,
    medicine_id,
    hospital_id,
    disease_id,
    hospital_name,
    disease_name,
    transaction_date,       
    transaction_time,
    quantity_prescribed,    
    quantity_dispensed,
    treatment_duration_days,
    daily_dose_frequency,
    dosage_instructions,
    unit_price,
    total_amount,
    pharmacist_id,
    doctor_id

from {{ source('raw', 'RAW_PRESCRIPTIONS') }}
