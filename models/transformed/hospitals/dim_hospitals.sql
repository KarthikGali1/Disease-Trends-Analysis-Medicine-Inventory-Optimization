SELECT DISTINCT
    rh.hospital_id::STRING AS hospital_id,
    rh.hospital_name::STRING AS hospital_name,
    TRY_TO_NUMBER(rh.bed_capacity) AS bed_capacity,
    rh.hospital_type::STRING AS hospital_type,
    rg.region_id::STRING AS city_id,
    TRY_TO_NUMBER(rh.established_year) AS established_year,
    rh.latitude::STRING AS latitude,
    rh.longitude::STRING AS longitude
FROM  --RAW_HOSPITALS
    {{ source('raw', 'RAW_HOSPITALS') }} AS rh
LEFT JOIN
    {{ ref('dim_geographic') }} AS rg ON rh.city = rg.city
                                   AND rh.state = rg.state
                                   AND rh.pincode = rg.pincode