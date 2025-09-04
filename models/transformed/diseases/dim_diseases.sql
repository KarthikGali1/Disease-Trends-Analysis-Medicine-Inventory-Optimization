SELECT DISTINCT
    rd.disease_id::STRING AS disease_id,
    rd.disease::STRING AS disease_name,
    rd.disease_category::STRING AS disease_category,
    MD5(TRIM(UPPER(rd.severity_levels)))::STRING AS severity_code,
    rd.transmission_type::STRING AS transmission_type,
    rd.seasonal_pattern::STRING AS seasonal_pattern
FROM --RAW_DISEASES_WITH_IDS
    {{ source('raw', 'RAW_DISEASES_WITH_IDS') }} AS rd