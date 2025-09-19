
create or replace table raw_drugs_with_ids (
    drug_id string,
    generic_name string,
    therapeutic_class string,
    dosage_form string,
    strength string,
    manufacturer string,
    drug_controller_approval string,
    shelf_life_months string,
    storage_temperature string,
    prescription_required string,
    schedule string,
    typical_daily_dose string,
    min_duration_days string,
    max_duration_days string,
    max_single_prescription string
);
