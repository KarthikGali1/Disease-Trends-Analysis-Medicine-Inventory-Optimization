SELECT
    ri.inventory_id::STRING AS inventory_id,
    ri.medicine_id::STRING AS drug_id,
    ri.hospital_id::STRING AS hospital_id,
    ri.supplier_id::STRING AS supplier_id,
    ri.batch_number::STRING AS batch_number,
    -- Convert STRING dates to DATE type
    TRY_TO_DATE(ri.order_date) AS order_date,
    TRY_TO_DATE(ri.batch_receipt_date) AS batch_receipt_date,
    TRY_TO_DATE(ri.expected_delivery_date) AS expected_delivery_date,
    TRY_TO_DATE(ri.manufacturing_date) AS manufacturing_date,
    TRY_TO_DATE(ri.expiry_date) AS expiry_date,
    -- Convert STRING numbers to NUMBER type
    TRY_TO_NUMBER(ri.shelf_life_days) AS shelf_life_days,
    TRY_TO_NUMBER(ri.days_to_expiry) AS days_to_expiry,
    TRY_TO_NUMBER(ri.current_stock_qty) AS current_stock_qty,
    TRY_TO_NUMBER(ri.reorder_level) AS reorder_level,
    TRY_TO_NUMBER(ri.max_stock_level) AS max_stock_level,
    TRY_TO_NUMBER(ri.unit_cost, 10, 4) AS unit_cost,
    TRY_TO_NUMBER(ri.wholesale_price, 10, 2) AS wholesale_price,
    TRY_TO_NUMBER(ri.retail_price, 10, 2) AS retail_price,
    TRY_TO_NUMBER(ri.mrp, 10, 2) AS mrp,
    TRY_TO_NUMBER(ri.gst_rate, 5, 2) AS gst_rate,
    ri.stock_status::STRING AS stock_status,
    ri.batch_status::STRING AS batch_status,
    ri.expiry_risk_level::STRING AS expiry_risk_level,
    -- Calculated analytics columns with explicits casting
    (CASE
        WHEN TRY_TO_DATE(ri.order_date) IS NOT NULL AND TRY_TO_DATE(ri.batch_receipt_date) IS NOT NULL
        THEN DATEDIFF('day', TRY_TO_DATE(ri.order_date), TRY_TO_DATE(ri.batch_receipt_date))
        ELSE NULL
    END)::NUMBER AS supplier_lead_time_days,
    (CASE
        WHEN TRY_TO_DATE(ri.expected_delivery_date) IS NOT NULL AND TRY_TO_DATE(ri.batch_receipt_date) IS NOT NULL
        THEN TRY_TO_DATE(ri.batch_receipt_date) <= TRY_TO_DATE(ri.expected_delivery_date)
        ELSE NULL
    END)::BOOLEAN AS is_on_time_delivery,
    (CASE
        WHEN TRY_TO_NUMBER(ri.daily_consumption) > 0 AND TRY_TO_NUMBER(ri.current_stock_qty) > 0
        THEN TRY_TO_NUMBER(ri.current_stock_qty) / TRY_TO_NUMBER(ri.daily_consumption)
        ELSE NULL
    END)::NUMBER AS days_on_hand,
    (CASE WHEN TRY_TO_NUMBER(ri.current_stock_qty) <= 0 THEN TRUE ELSE FALSE END)::BOOLEAN AS is_stockout,
    (CASE WHEN TRY_TO_NUMBER(ri.current_stock_qty) <= TRY_TO_NUMBER(ri.reorder_level) THEN TRUE ELSE FALSE END)::BOOLEAN AS is_below_reorder,
    (CASE
        WHEN ri.batch_status = 'Expired' OR TRY_TO_DATE(ri.expiry_date) < CURRENT_DATE() THEN TRUE
        ELSE FALSE
    END)::BOOLEAN AS is_expired,
    (CASE
        WHEN ri.batch_status = 'Expired' OR TRY_TO_DATE(ri.expiry_date) < CURRENT_DATE()
        THEN TRY_TO_NUMBER(ri.current_stock_qty) * TRY_TO_NUMBER(ri.unit_cost)
        ELSE 0
    END)::NUMBER(12, 2) AS expired_stock_value,
    (CASE
        WHEN TRY_TO_NUMBER(ri.current_stock_qty) <= TRY_TO_NUMBER(ri.reorder_level) THEN 'Fast Moving'
        WHEN TRY_TO_NUMBER(ri.current_stock_qty) >= TRY_TO_NUMBER(ri.max_stock_level) * 0.8 THEN 'Slow Moving'
        ELSE 'Normal'
    END)::STRING AS inventory_turnover_indicator,
    (CASE
        WHEN TRY_TO_NUMBER(ri.unit_cost) > 0 AND TRY_TO_NUMBER(ri.retail_price) > 0
        THEN (TRY_TO_NUMBER(ri.retail_price) - TRY_TO_NUMBER(ri.unit_cost)) / TRY_TO_NUMBER(ri.retail_price)
        ELSE NULL
    END)::NUMBER(5, 4) AS profit_margin,
    YEAR(TRY_TO_DATE(ri.order_date))::NUMBER AS order_year,
    MONTH(TRY_TO_DATE(ri.order_date))::NUMBER AS order_month,
    YEAR(TRY_TO_DATE(ri.batch_receipt_date))::NUMBER AS receipt_year,
    MONTH(TRY_TO_DATE(ri.batch_receipt_date))::NUMBER AS receipt_month
FROM
    {{ source('raw', 'RAW_INVENTORY') }} AS ri
WHERE
    ri.inventory_id IS NOT NULL