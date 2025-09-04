SELECT DISTINCT
    rp.patient_id::STRING AS patient_id,
    rp.patient_name::STRING AS patient_name,
    rp.patient_age::NUMBER AS patient_age,
    rp.patient_gender::STRING AS patient_gender,
    rp.blood_group::STRING AS blood_group,
    rp.govt_scheme::STRING AS govt_scheme,
    rp.insurance_provider::STRING AS insurance_provider,
    rg.region_id::STRING AS city_id,
    rp.registration_date::DATE AS registration_date
FROM --RAW_PATIENTS
    {{ source('raw', 'RAW_PATIENTS') }} AS rp
LEFT JOIN
    {{ ref('dim_geographic') }} AS rg ON rp.city = rg.city
                                   AND rp.state = rg.state
                                   AND rp.pincode = rg.pincode