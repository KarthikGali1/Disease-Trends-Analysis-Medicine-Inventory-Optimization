{{ config(materialized='table') }}

with src as (select * from {{ ref('stg_inventory') }})
select
  cast(src.medicine_id as string) as drug_sk,
  cast(src.hospital_id as string) as location_sk,
  cast(src.supplier_id as string) as supplier_sk,
  src.*
from src
