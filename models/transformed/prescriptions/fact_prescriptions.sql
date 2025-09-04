SELECT
    rp.prescription_id::STRING AS prescription_id,
    rp.patient_id::STRING AS patient_id,
    rp.hospital_id::STRING AS hospital_id,
    rp.disease_id::STRING AS disease_id,
    rp.medicine_id::STRING AS drug_id,
    TRY_TO_DATE(rp.transaction_date) AS transaction_date,
    TRY_TO_NUMBER(rp.quantity_prescribed, 10, 0) AS quantity_prescribed,
    TRY_TO_NUMBER(rp.quantity_dispensed, 10, 0) AS quantity_dispensed,
    TRY_TO_NUMBER(rp.treatment_duration_days, 10, 0) AS treatment_duration_days,
    TRY_TO_NUMBER(rp.daily_dose_frequency, 10, 0) AS daily_dose_frequency,
    rp.dosage_instructions::STRING AS dosage_instructions,
    TRY_TO_NUMBER(rp.unit_price, 10, 2) AS unit_price,
    TRY_TO_NUMBER(rp.total_amount, 12, 2) AS total_amount,
    rp.payment_method::STRING AS payment_method,
    rp.prescription_status::STRING AS prescription_status,
    rp.doctor_id::STRING AS doctor_id,
    rp.pharmacist_id::STRING AS pharmacist_id,
    -- Calculated analytics columns with explicits casting
    (CASE
        WHEN TRY_TO_NUMBER(rp.quantity_prescribed, 10, 0) > 0
        THEN TRY_TO_NUMBER(rp.quantity_dispensed, 10, 0) / TRY_TO_NUMBER(rp.quantity_prescribed, 10, 0)
        ELSE NULL
    END)::NUMBER(5, 4) AS demand_fulfillment_rate,
    (CASE
        WHEN TRY_TO_NUMBER(rp.quantity_dispensed, 10, 0) > 0
        THEN TRY_TO_NUMBER(rp.total_amount, 12, 2) / TRY_TO_NUMBER(rp.quantity_dispensed, 10, 0)
        ELSE NULL
    END)::NUMBER(10, 2) AS revenue_per_unit,
    YEAR(TRY_TO_DATE(rp.transaction_date))::NUMBER AS transaction_year,
    MONTH(TRY_TO_DATE(rp.transaction_date))::NUMBER AS transaction_month,
    WEEKOFYEAR(TRY_TO_DATE(rp.transaction_date))::NUMBER AS transaction_week,
    (CASE
        WHEN TRY_TO_NUMBER(rp.quantity_dispensed, 10, 0) >= TRY_TO_NUMBER(rp.quantity_prescribed, 10, 0)
        THEN TRUE
        ELSE FALSE
    END)::BOOLEAN AS is_fully_dispensed
FROM
    {{ source('raw', 'RAW_PRESCRIPTIONS') }} AS rp
WHERE
    rp.prescription_id IS NOT NULL









