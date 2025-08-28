{{ config(materialized='table') }}

select
  cast(drug_id as string) as drug_sk,
  *
from {{ ref('stg_drugs') }}
