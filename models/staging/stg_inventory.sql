{{ config(materialized = 'view') }}

select
    cast(inventory_id as string) as inventory_id,                       
    initcap(trim(medicine_name)) as medicine_name,                  
    nullif(current_stock_qty, '')::integer as current_stock_qty,        -- numeric stock qty
    nullif(unit_cost, '')::numeric as unit_cost,                        -- numeric cost
    medicine_id,
    hospital_id,
    supplier_id,
    hospital_name,
    supplier_name,
    batch_number,
    batch_receipt_date,
    manufacturing_date,
    expiry_date,
    shelf_life_days,
    days_to_expiry,
    reorder_level,
    max_stock_level,
    wholesale_price,
    retail_price,
    mrp,
    gst_rate,
    stock_status,
    batch_status,
    expiry_risk_level

from {{ source('raw', 'RAW_INVENTORY') }}
