{{ config(
    materialized='table',
    schema='PATIENTS',
    alias='FACT_PRESCRIPTIONS'
) }}

with src as (
    select
        /* -----------------------
           Foreign Keys (business keys)
        ------------------------ */
        try_to_date(transaction_date)     as transaction_date_key,
        cast(patient_id  as varchar)      as patient_key,
        cast(medicine_id as varchar)      as medicine_key,
        cast(hospital_id as varchar)      as hospital_key,
        cast(disease_id  as varchar)      as disease_key,
        /* If supplier_id exists in staging, replace NULL below with cast(supplier_id as varchar) */
        NULL::varchar                     as supplier_key,

        /* -----------------------
           Degenerate Dimensions
        ------------------------ */
        cast(prescription_id as varchar)  as prescription_id,
        /* If a separate transaction_id exists, replace NULL below with cast(transaction_id as varchar) */
        NULL::varchar                     as transaction_id,

        /* -----------------------
           Measures - Quantity
        ------------------------ */
        try_to_number(quantity_prescribed) as quantity_prescribed,
        try_to_number(quantity_dispensed)  as quantity_dispensed,

        /* -----------------------
           Measures - Financial
        ------------------------ */
        try_to_number(unit_price)   as unit_price,
        try_to_number(total_amount) as total_amount,

        /* -----------------------
           Attributes
        ------------------------ */
        try_to_number(treatment_duration_days) as treatment_duration_days,
        try_to_number(daily_dose_frequency)    as daily_dose_frequency,
        dosage_instructions,

        /* -----------------------
           Status
        ------------------------ */
        payment_method,
        prescription_status,

        /* -----------------------
           Personnel
        ------------------------ */
        cast(pharmacist_id as varchar) as pharmacist_id,
        cast(doctor_id     as varchar) as doctor_id,

        /* -----------------------
           Timestamps
        ------------------------ */
        try_to_date(transaction_date)              as transaction_date,
        try_to_time(transaction_time)              as transaction_time

    from {{ ref('stg_prescriptions') }}
),

/* -----------------------
   Measures - Derived (simple, safe math)
------------------------ */
final as (
    select
        transaction_date_key,
        patient_key,
        medicine_key,
        hospital_key,
        disease_key,
        supplier_key,

        prescription_id,
        transaction_id,

        quantity_prescribed,
        quantity_dispensed,
        unit_price,
        total_amount,

        /* Derived */
        case
            when nullif(quantity_prescribed, 0) is null then null
            else quantity_dispensed / nullif(quantity_prescribed, 0)
        end as medicine_utilization_rate,

        case
            when nullif(treatment_duration_days, 0) is null then null
            else total_amount / nullif(treatment_duration_days, 0)
        end as cost_per_day_treatment,

        case
            when nullif(treatment_duration_days, 0) is null then null
            else quantity_dispensed / nullif(treatment_duration_days, 0)
        end as daily_consumption_rate,

        /* Attributes / Status / Personnel */
        treatment_duration_days,
        daily_dose_frequency,
        dosage_instructions,

        payment_method,
        prescription_status,

        pharmacist_id,
        doctor_id,

        /* Timestamps */
        transaction_date,
        transaction_time
    from src
)

select * from final
