<<<<<<< HEAD
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
=======
SELECT 
    MD5(patient_id) AS patient_sk,      -- surrogate key
    patient_id,
    patient_name,
    TRY_CAST(patient_age AS INTEGER) AS patient_age,

    -- Standardize gender
    CASE 
        WHEN patient_gender ILIKE 'M%' THEN 'Male'
        WHEN patient_gender ILIKE 'F%' THEN 'Female'
        WHEN patient_gender ILIKE 'O%' THEN 'Other'
        ELSE 'Unknown'
    END AS standardized_gender,

    blood_group,

    -- Clean phone: remove +91, keep last 10 digits
    RIGHT(REGEXP_REPLACE(contact_phone, '[^0-9]', ''), 10) AS clean_contact_phone,
    RIGHT(REGEXP_REPLACE(emergency_contact, '[^0-9]', ''), 10) AS clean_emergency_contact,

    email,
    address,
    city,
    state,
    pincode,
    insurance_provider,
    govt_scheme,
    TRY_CAST(registration_date AS DATE) AS registration_date,

    -- Age group bucketing
    CASE 
        WHEN TRY_CAST(patient_age AS INTEGER) BETWEEN 0 AND 12 THEN 'Child'
        WHEN TRY_CAST(patient_age AS INTEGER) BETWEEN 13 AND 19 THEN 'Teen'
        WHEN TRY_CAST(patient_age AS INTEGER) BETWEEN 20 AND 39 THEN 'Young Adult'
        WHEN TRY_CAST(patient_age AS INTEGER) BETWEEN 40 AND 59 THEN 'Middle Age'
        WHEN TRY_CAST(patient_age AS INTEGER) >= 60 THEN 'Senior'
        ELSE 'Unknown'
    END AS age_group,

    -- Payment category
    CASE 
        WHEN govt_scheme IS NOT NULL AND govt_scheme != '' THEN 'Government'
        WHEN insurance_provider IS NOT NULL AND insurance_provider != '' THEN 'Private Insurance'
        ELSE 'Self Pay'
    END AS payment_category,

    -- Date parts
    EXTRACT(YEAR FROM TRY_CAST(registration_date AS DATE)) AS registration_year,
    EXTRACT(MONTH FROM TRY_CAST(registration_date AS DATE)) AS registration_month

FROM --raw_patients
{{source('raw','RAW_PATIENTS')}}
>>>>>>> f32683793d8c78617c88e71cc31e1bcdfe2789f5
