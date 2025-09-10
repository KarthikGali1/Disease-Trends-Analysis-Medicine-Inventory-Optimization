WITH
total_inventory_value AS (
    SELECT SUM(fi.current_stock_qty * fi.unit_cost) AS total_inventory_value
    FROM TRANSFORMED_DB_DEV.INVENTORY.fact_inventory fi
    WHERE fi.hospital_id = 'H001'
),
total_skus AS (
    SELECT COUNT(DISTINCT fi.drug_id) AS total_skus
    FROM TRANSFORMED_DB_DEV.INVENTORY.fact_inventory fi
    WHERE fi.hospital_id = 'H001'
),
active_inactive_skus AS (
    SELECT
        COUNT(DISTINCT CASE WHEN fi.current_stock_qty > 0 THEN fi.drug_id END) AS active_skus,
        COUNT(DISTINCT CASE WHEN fi.current_stock_qty = 0 THEN fi.drug_id END) AS inactive_skus
    FROM TRANSFORMED_DB_DEV.INVENTORY.fact_inventory fi
    WHERE fi.hospital_id = 'H001'
),
stockout_rate AS (
    SELECT (COUNT(CASE WHEN fi.is_stockout = TRUE THEN 1 END) * 100.0 / COUNT(*)) AS stockout_rate_percentage
    FROM TRANSFORMED_DB_DEV.INVENTORY.fact_inventory fi
    WHERE fi.hospital_id = 'H001'
),
below_reorder_rate AS (
    SELECT (COUNT(CASE WHEN fi.is_below_reorder = TRUE THEN 1 END) * 100.0 / COUNT(*)) AS below_reorder_rate_percentage
    FROM TRANSFORMED_DB_DEV.INVENTORY.fact_inventory fi
    WHERE fi.hospital_id = 'H001'
),
overstock_rate AS (
    SELECT (COUNT(CASE WHEN fi.current_stock_qty > fi.max_stock_level THEN 1 END) * 100.0 / COUNT(*)) AS overstock_rate_percentage
    FROM TRANSFORMED_DB_DEV.INVENTORY.fact_inventory fi
    WHERE fi.hospital_id = 'H001' AND fi.max_stock_level > 0
),
avg_days_on_hand AS (
    SELECT AVG(fi.days_on_hand) AS avg_days_on_hand
    FROM TRANSFORMED_DB_DEV.INVENTORY.fact_inventory fi
    WHERE fi.hospital_id = 'H001' AND fi.days_on_hand IS NOT NULL
),
expired_value AS (
    SELECT SUM(fi.expired_stock_value) AS total_expired_value
    FROM TRANSFORMED_DB_DEV.INVENTORY.fact_inventory fi
    WHERE fi.hospital_id = 'H001' AND fi.is_expired = TRUE
),
near_expiry_value AS (
    SELECT SUM(fi.current_stock_qty * fi.unit_cost) AS near_expiry_value
    FROM TRANSFORMED_DB_DEV.INVENTORY.fact_inventory fi
    WHERE fi.hospital_id = 'H001' AND fi.days_to_expiry BETWEEN 1 AND 30
),
expired_stock_rate AS (
    SELECT (COUNT(CASE WHEN fi.is_expired = TRUE THEN 1 END) * 100.0 / COUNT(*)) AS expired_stock_rate_percentage
    FROM TRANSFORMED_DB_DEV.INVENTORY.fact_inventory fi
    WHERE fi.hospital_id = 'H001'
),
-- FINANCIAL KPIs
inventory_turnover AS (
    SELECT AVG(aff.inventory_turnover) AS average_inventory_turnover
    FROM TRANSFORMED_DB_DEV.agg_financials.agg_fact_financials aff
    WHERE aff.hospital_id = 'H001'
),
gmroi AS (
    SELECT AVG(aff.GMROI) AS average_gmroi
    FROM TRANSFORMED_DB_DEV.agg_financials.agg_fact_financials aff
    WHERE aff.hospital_id = 'H001'
),
profit_margin AS (
    SELECT AVG(fi.profit_margin) * 100 AS avg_profit_margin_percentage
    FROM TRANSFORMED_DB_DEV.INVENTORY.fact_inventory fi
    WHERE fi.hospital_id = 'H001' AND fi.profit_margin IS NOT NULL
),
holding_cost AS (
    SELECT SUM(fi.current_stock_qty * fi.unit_cost * 0.25) AS estimated_annual_holding_cost
    FROM TRANSFORMED_DB_DEV.INVENTORY.fact_inventory fi
    WHERE fi.hospital_id = 'H001'
),
dead_stock_value AS (
    SELECT SUM(fi.current_stock_qty * fi.unit_cost) AS dead_stock_value
    FROM TRANSFORMED_DB_DEV.INVENTORY.fact_inventory fi
    WHERE fi.hospital_id = 'H001'
      AND fi.inventory_turnover_indicator = 'Slow Moving'
      AND fi.current_stock_qty > 0
),
-- DEMAND KPIs
demand_fulfillment AS (
    SELECT AVG(fp.demand_fulfillment_rate) * 100 AS avg_demand_fulfillment_percentage
    FROM TRANSFORMED_DB_DEV.prescriptions.fact_prescriptions fp
    WHERE fp.hospital_id = 'H001' AND fp.demand_fulfillment_rate IS NOT NULL
),
backorder_rate AS (
    SELECT (COUNT(CASE WHEN fp.quantity_dispensed < fp.quantity_prescribed THEN 1 END) * 100.0 / COUNT(*)) AS backorder_rate_percentage
    FROM TRANSFORMED_DB_DEV.prescriptions.fact_prescriptions fp
    WHERE fp.hospital_id = 'H001'
),
avg_stock_coverage AS (
    SELECT AVG(fi.current_stock_qty / NULLIF(dc.avg_consumption,0)) AS avg_stock_coverage_days
    FROM TRANSFORMED_DB_DEV.INVENTORY.fact_inventory fi
    JOIN (
        SELECT drug_id, hospital_id, AVG(quantity_dispensed) AS avg_consumption
        FROM TRANSFORMED_DB_DEV.prescriptions.fact_prescriptions
        WHERE transaction_date >= CURRENT_DATE - 30
        GROUP BY drug_id, hospital_id
    ) dc ON fi.drug_id = dc.drug_id AND fi.hospital_id = dc.hospital_id
    WHERE fi.hospital_id = 'H001' AND fi.current_stock_qty > 0
)
-- FINAL SELECT
SELECT
    tiv.total_inventory_value,
    ts.total_skus,
    ais.active_skus,
    ais.inactive_skus,
    sr.stockout_rate_percentage,
    br.below_reorder_rate_percentage,
    orr.overstock_rate_percentage,
    doh.avg_days_on_hand,
    ev.total_expired_value,
    nev.near_expiry_value,
    esr.expired_stock_rate_percentage,
    it.average_inventory_turnover,
    g.average_gmroi,
    pm.avg_profit_margin_percentage,
    hc.estimated_annual_holding_cost,
    dsv.dead_stock_value,
    df.avg_demand_fulfillment_percentage,
    bor.backorder_rate_percentage,
    asc.avg_stock_coverage_days
FROM total_inventory_value tiv
CROSS JOIN total_skus ts
CROSS JOIN active_inactive_skus ais
CROSS JOIN stockout_rate sr
CROSS JOIN below_reorder_rate br
CROSS JOIN overstock_rate orr
CROSS JOIN avg_days_on_hand doh
CROSS JOIN expired_value ev
CROSS JOIN near_expiry_value nev
CROSS JOIN expired_stock_rate esr
CROSS JOIN inventory_turnover it
CROSS JOIN gmroi g
CROSS JOIN profit_margin pm
CROSS JOIN holding_cost hc
CROSS JOIN dead_stock_value dsv
CROSS JOIN demand_fulfillment df
CROSS JOIN backorder_rate bor
CROSS JOIN avg_stock_coverage asc;