SELECT DISTINCT
    rdw.drug_id::STRING AS drug_id,
    rdw.generic_name::STRING AS generic_name,
    rdw.therapeutic_class::STRING AS therapeutic_class,
    rdw.dosage_form::STRING AS dosage_form,
    rdw.strength::STRING AS strength,
    rdw.manufacturer::STRING AS manufacturer,
    rdw.prescription_required::STRING AS prescription_required,
    TRY_TO_NUMBER(rdw.shelf_life_months) AS shelf_life_months
FROM --RAW_DRUGS_WITH_IDS
    {{ source('raw', 'RAW_DRUGS_WITH_IDS') }} AS rdw