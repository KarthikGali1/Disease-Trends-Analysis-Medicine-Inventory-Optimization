SELECT
    fi.hospital_id::STRING AS hospital_id,
    fi.drug_id::STRING AS drug_id,
    SUM(fp.total_amount)::NUMBER(38, 2) AS total_revenue,
    SUM(fp.quantity_dispensed * fi.unit_cost)::NUMBER(38, 2) AS cogs,
    SUM(fp.total_amount - (fp.quantity_dispensed * fi.unit_cost))::NUMBER(38, 2) AS gross_margin,
    -- GMROI = Gross Margin / Average Inventory Investment
    (CASE
        WHEN AVG(fi.current_stock_qty * fi.unit_cost) > 0
        THEN SUM(fp.total_amount - (fp.quantity_dispensed * fi.unit_cost))
             / AVG(fi.current_stock_qty * fi.unit_cost)
    END)::NUMBER(38, 4) AS GMROI,
    -- Turnover = COGS / Average Inventory Values
    (CASE
        WHEN AVG(fi.current_stock_qty * fi.unit_cost) > 0
        THEN SUM(fp.quantity_dispensed * fi.unit_cost) / AVG(fi.current_stock_qty * fi.unit_cost)
    END)::NUMBER(38, 4) AS inventory_turnover
FROM
    {{ ref('fact_inventory') }} AS fi
JOIN
    {{ ref('fact_prescriptions') }} AS fp
    ON fi.drug_id = fp.drug_id
    AND fi.hospital_id = fp.hospital_id
GROUP BY
    fi.hospital_id,
    fi.drug_id 