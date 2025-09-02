{{ config(materialized = 'view') }}

select
    cast(supplier_id as string) as supplier_id,            -- ensure string
    initcap(trim(supplier_name)) as supplier_name,         -- clean formatting
    lower(trim(contact_email)) as contact_email,           -- normalize email
    nullif(established_year, '')::integer as established_year, -- numeric year
    initcap(trim(certification_status)) as certification_status, -- tidy formatting
    supplier_city,
    supplier_state,
    supplier_gst_number,
    supplier_drug_license,
    contact_phone,
    supplier_type

from {{ source('raw', 'RAW_SUPPLIERS') }}
