{{ config(materialized='table') }}

select
  cast(supplier_id as string) as supplier_sk,  -- use natural key directly
  *
from {{ ref('stg_suppliers') }}
