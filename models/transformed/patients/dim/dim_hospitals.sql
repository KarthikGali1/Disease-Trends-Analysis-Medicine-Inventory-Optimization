{{ config(
    materialized='table',
    schema='PATIENTS',
    alias='DIM_HOSPITALS'
) }}

select
    hospital_id,
    hospital_name,
    email,
    bed_capacity,
    established_year,
    hospital_location,
    city,
    state,
    region,
    tier,
    pincode,
    hospital_type,
    hospital_tier,
    latitude,
    longitude,
    contact_phone
from {{ ref('stg_hospitals') }}
