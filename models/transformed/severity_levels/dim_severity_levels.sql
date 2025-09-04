SELECT DISTINCT
    MD5(TRIM(UPPER(severity_levels)))::STRING AS severity_code,
    severity_levels::STRING AS severity_raw,
    (CASE
        WHEN UPPER(severity_levels) LIKE '%MILD%' THEN 'mild'
        WHEN UPPER(severity_levels) LIKE '%MODERATE%' THEN 'moderate'
        WHEN UPPER(severity_levels) LIKE '%SEVERE%' THEN 'severe'
        WHEN UPPER(severity_levels) LIKE '%CRITICAL%' THEN 'critical'
        ELSE 'other'
    END)::STRING AS severity_normalized
FROM --RAW_DISEASES_WITH_IDS
    {{ source('raw', 'RAW_DISEASES_WITH_IDS') }}