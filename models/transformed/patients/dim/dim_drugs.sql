{{ config(
    materialized='table',
    schema='INVENTORY',
    alias='DIM_MEDICINE'
) }}

select
    -- Keys
    medicine_id,

    -- Basic Info
    generic_name,
    therapeutic_class,
    dosage_form,
    strength,

    -- Manufacturing
    manufacturer,
    drug_controller_approval,

    -- Storage
    shelf_life_months,
    storage_temperature,

    -- Prescription
    prescription_required,
    schedule,

    -- Dosage
    typical_daily_dose,
    min_duration_days,
    max_duration_days,
    max_single_prescription,

    -- Derived Classification
    medicine_category,
    medicine_substitute,

    -- Audit
    effective_date,
    expiry_date,
    case
        when expiry_date is null or expiry_date >= current_date then true
        else false
    end as is_current

from {{ ref('stg_drugs') }}