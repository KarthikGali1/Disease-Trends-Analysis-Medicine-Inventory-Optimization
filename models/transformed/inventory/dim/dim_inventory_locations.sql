{{ config(materialized='table') }}

select
  cast(hospital_id as string) as location_sk,
  *
from {{ ref('stg_hospitals') }}
