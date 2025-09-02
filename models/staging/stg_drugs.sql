{{ config(materialized='view') }}

select
    drug_id,
    initcap(trim(generic_name)) as generic_name,
    initcap(trim(therapeutic_class)) as therapeutic_class,
    initcap(trim(dosage_form)) as dosage_form,
    strength,
    initcap(trim(manufacturer)) as manufacturer,
    drug_controller_approval,
    shelf_life_months,
    storage_temperature,
    prescription_required,
    schedule,
    typical_daily_dose,
    min_duration_days,
    max_duration_days,
    max_single_prescription
from {{ source('raw', 'RAW_DRUGS_WITH_IDS') }}
