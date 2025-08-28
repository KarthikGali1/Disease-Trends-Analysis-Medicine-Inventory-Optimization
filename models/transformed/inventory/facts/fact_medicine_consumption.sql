{{ config(materialized='table') }}

with src as (select * from {{ ref('stg_prescriptions') }})
select
  cast(src.medicine_id as string) as drug_sk,
  cast(src.hospital_id as string) as location_sk,
  cast(src.patient_id  as string) as patient_sk,
  cast(src.disease_id  as string) as disease_sk,
  src.*
from src