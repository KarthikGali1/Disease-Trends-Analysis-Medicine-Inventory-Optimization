SELECT DISTINCT
    rs.supplier_id::STRING AS supplier_id,
    rs.supplier_name::STRING AS supplier_name,
    rs.supplier_type::STRING AS supplier_type,
    rg.region_id::STRING AS city_id,
    TRY_TO_NUMBER(rs.established_year) AS established_year,
    rs.certification_status::STRING AS certification_status
FROM --RAW_SUPPLIERS
    {{ source('raw', 'RAW_SUPPLIERS') }} AS rs
LEFT JOIN
    {{ ref('dim_geographic') }} AS rg
        ON rs.supplier_city = rg.city
       AND rs.supplier_state = rg.state