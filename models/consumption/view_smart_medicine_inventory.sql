with daily_consumption as (
    -- Calculate average daily consumption for each drug over the last 90 days for stock coverage calculation
    select
        drug_id,
        hospital_id,
        avg(quantity_dispensed) as avg_daily_consumption
    from {{ ref('fact_prescriptions') }}
    where transaction_date >= current_date - 90
    group by drug_id, hospital_id
),

prescription_kpis as (
    -- Aggregate prescription-based KPIs at the drug and hospital level
    select
        drug_id,
        hospital_id,
        avg(demand_fulfillment_rate) as avg_demand_fulfillment_rate,
        (count(case when quantity_dispensed < quantity_prescribed then 1 end) * 100.0 / count(prescription_id)) as backorder_rate_percentage
    from {{ ref('fact_prescriptions') }}
    group by drug_id, hospital_id
),

hospital_level_kpis as (
    -- Calculate hospital-level aggregated KPIs using window functions
    select
        inventory_id,
        hospital_id,
        -- Count-based KPIs per hospital
        count(distinct drug_id) over (partition by hospital_id) as hospital_total_skus,
        count(distinct case when current_stock_qty > 0 then drug_id end) over (partition by hospital_id) as hospital_active_skus,
        count(distinct case when current_stock_qty = 0 then drug_id end) over (partition by hospital_id) as hospital_inactive_skus,
        
        -- Rate calculations per hospital (as percentages)
        (count(case when is_stockout = true then 1 end) over (partition by hospital_id) * 100.0 / 
         count(*) over (partition by hospital_id)) as hospital_stockout_rate,
        
        (count(case when is_below_reorder = true then 1 end) over (partition by hospital_id) * 100.0 / 
         count(*) over (partition by hospital_id)) as hospital_below_reorder_rate,
        
        (count(case when current_stock_qty > max_stock_level and max_stock_level > 0 then 1 end) over (partition by hospital_id) * 100.0 / 
         count(case when max_stock_level > 0 then 1 end) over (partition by hospital_id)) as hospital_overstock_rate,
        
        (count(case when is_expired = true then 1 end) over (partition by hospital_id) * 100.0 / 
         count(*) over (partition by hospital_id)) as hospital_expired_rate,
        
        (count(case when stock_status = 'In Stock' then 1 end) over (partition by hospital_id) * 100.0 / 
         count(*) over (partition by hospital_id)) as hospital_inventory_accuracy_rate,
        
        -- Average calculations per hospital
        avg(days_on_hand) over (partition by hospital_id) as hospital_avg_days_on_hand,
        avg(profit_margin) over (partition by hospital_id) * 100 as hospital_avg_profit_margin_pct,
        
        -- Total values per hospital
        sum(current_stock_qty * unit_cost) over (partition by hospital_id) as hospital_total_inventory_value,
        sum(expired_stock_value) over (partition by hospital_id) as hospital_total_expired_value
        
    from {{ ref('fact_inventory') }}
),

supplier_level_kpis as (
    -- Calculate supplier-level aggregated KPIs using window functions
    select
        inventory_id,
        supplier_id,
        -- Supplier performance metrics
        avg(supplier_lead_time_days) over (partition by supplier_id) as supplier_avg_lead_time,
        
        (count(case when is_on_time_delivery = true then 1 end) over (partition by supplier_id) * 100.0 / 
         count(*) over (partition by supplier_id)) as supplier_on_time_delivery_rate,
        
        (sum(case when current_stock_qty >= reorder_level then 1 else 0 end) over (partition by supplier_id) * 100.0 / 
         count(*) over (partition by supplier_id)) as supplier_fill_rate,
        
        (count(case when batch_status in ('Expired', 'Damaged', 'Recalled') then 1 end) over (partition by supplier_id) * 100.0 / 
         count(*) over (partition by supplier_id)) as supplier_quality_issues_rate,
         
        count(distinct drug_id) over (partition by supplier_id) as supplier_distinct_drugs,
        sum(current_stock_qty * unit_cost) over (partition by supplier_id) as supplier_inventory_value
        
    from {{ ref('fact_inventory') }}
    where batch_receipt_date is not null -- Only consider delivered orders for supplier metrics
),

inventory_classification as (
    -- ABC analysis and movement classification
    select
        inventory_id,
        drug_id,
        hospital_id,
        current_stock_qty * unit_cost as inventory_value,
        case
            when days_on_hand <= 7 then 'Fast Moving'
            when days_on_hand <= 30 then 'Medium Moving'
            when days_on_hand <= 90 then 'Slow Moving'
            else 'Dead Stock'
        end as movement_category,
        
        -- Seasonality classification based on admission patterns
        case
            when extract(month from order_date) in (6,7,8,9) then 'Monsoon Season'
            when extract(month from order_date) in (12,1,2) then 'Winter Season'
            when extract(month from order_date) in (3,4,5) then 'Summer Season'
            when extract(month from order_date) in (10,11) then 'Post-Monsoon'
            else 'Unknown'
        end as seasonal_pattern,
        
        -- Risk categorization
        case
            when is_expired = true then 'High Risk - Expired'
            when days_to_expiry <= 30 then 'High Risk - Near Expiry'
            when is_stockout = true then 'High Risk - Stockout'
            when is_below_reorder = true then 'Medium Risk - Below Reorder'
            when current_stock_qty > max_stock_level then 'Medium Risk - Overstock'
            else 'Low Risk'
        end as risk_category
        
    from {{ ref('fact_inventory') }}
),

financial_metrics as (
    -- Enhanced financial calculations
    select
        inventory_id,
        drug_id,
        hospital_id,
        current_stock_qty * unit_cost as total_inventory_value,
        
        -- Estimated holding cost (25% annual rate)
        (current_stock_qty * unit_cost * (0.25 / 365)) as estimated_daily_holding_cost,
        (current_stock_qty * unit_cost * 0.25) as estimated_annual_holding_cost,
        
        -- Dead stock value calculation
        case
            when inventory_turnover_indicator = 'Slow Moving' and current_stock_qty > 0 
            then (current_stock_qty * unit_cost)
            else 0
        end as dead_stock_value,
        
        -- Near expiry value
        case
            when days_to_expiry between 1 and 30 
            then (current_stock_qty * unit_cost)
            else 0
        end as near_expiry_value,
        
        -- Profit potential
        case
            when retail_price > 0 and unit_cost > 0
            then ((retail_price - unit_cost) * current_stock_qty)
            else 0
        end as potential_profit,
        
        -- Working capital tied up
        current_stock_qty * unit_cost as working_capital_invested
        
    from {{ ref('fact_inventory') }}
)

select
    -- ===== Primary Keys & Foreign Keys =====
    fi.inventory_id,
    fi.drug_id,
    fi.hospital_id,
    fi.supplier_id,
    fi.batch_number,
    
    -- ===== Dimension Attributes =====
    dd.generic_name,
    dd.therapeutic_class,
    dd.dosage_form,
    dd.strength,
    dd.manufacturer,
    dd.prescription_required,
    dd.shelf_life_months,
    ds.supplier_name,
    ds.supplier_type,
    ds.certification_status,
    dh.hospital_name,
    dh.hospital_type,
    dh.bed_capacity,
    dh.latitude as hospital_latitude,
    dh.longitude as hospital_longitude,
    
    -- ===== Core Inventory Metrics =====
    fi.current_stock_qty,
    fi.unit_cost,
    fi.wholesale_price,
    fi.retail_price,
    fi.mrp,
    fi.gst_rate,
    fi.reorder_level,
    fi.max_stock_level,
    fm.total_inventory_value,
    fi.stock_status,
    
    -- ===== Classification & Categorization =====
    ic.movement_category,
    ic.seasonal_pattern,
    ic.risk_category,
    fi.inventory_turnover_indicator,
    
    -- ===== Expiry & Quality KPIs =====
    fi.expiry_date,
    fi.days_to_expiry,
    fi.shelf_life_days,
    fi.is_expired,
    fi.expired_stock_value,
    fi.expiry_risk_level,
    fm.near_expiry_value,
    fi.batch_status,
    (case when fi.batch_status in ('Expired', 'Damaged', 'Recalled') then true else false end) as has_quality_issue,
    
    -- ===== Stock Level KPIs =====
    fi.is_stockout,
    fi.is_below_reorder,
    (fi.current_stock_qty > fi.max_stock_level) as is_overstock,
    fi.days_on_hand,
    
    -- ===== Financial KPIs =====
    fi.profit_margin,
    aff.inventory_turnover,
    aff.gmroi,
    aff.total_revenue,
    aff.gross_margin,
    aff.cogs,
    fm.estimated_daily_holding_cost,
    fm.estimated_annual_holding_cost,
    fm.dead_stock_value,
    fm.potential_profit,
    fm.working_capital_invested,
    
    -- ===== Supplier Performance KPIs =====
    fi.supplier_lead_time_days,
    fi.is_on_time_delivery,
    fi.expected_delivery_date,
    
    -- ===== Demand & Fulfillment KPIs =====
    pk.avg_demand_fulfillment_rate,
    pk.backorder_rate_percentage,
    dc.avg_daily_consumption,
    
    -- Stock Coverage in Days
    case
        when dc.avg_daily_consumption > 0 
        then (fi.current_stock_qty / dc.avg_daily_consumption)
        else null
    end as stock_coverage_days,
    
    -- ===== HOSPITAL-LEVEL AGGREGATED METRICS =====
    hkpi.hospital_total_skus,
    hkpi.hospital_active_skus,
    hkpi.hospital_inactive_skus,
    hkpi.hospital_stockout_rate,
    hkpi.hospital_below_reorder_rate,
    hkpi.hospital_overstock_rate,
    hkpi.hospital_expired_rate,
    hkpi.hospital_inventory_accuracy_rate,
    hkpi.hospital_avg_days_on_hand,
    hkpi.hospital_avg_profit_margin_pct,
    hkpi.hospital_total_inventory_value,
    hkpi.hospital_total_expired_value,
    
    -- ===== SUPPLIER-LEVEL AGGREGATED METRICS =====
    skpi.supplier_avg_lead_time,
    skpi.supplier_on_time_delivery_rate,
    skpi.supplier_fill_rate,
    skpi.supplier_quality_issues_rate,
    skpi.supplier_distinct_drugs,
    skpi.supplier_inventory_value,
    
    -- ===== Date/Time Columns for Filtering =====
    fi.order_date,
    fi.batch_receipt_date,
    fi.manufacturing_date,
    fi.order_year,
    fi.order_month,
    fi.receipt_year,
    fi.receipt_month,
    
    -- ===== Time-based Analysis =====
    extract(year from fi.order_date) as order_year_extracted,
    extract(month from fi.order_date) as order_month_extracted,
    extract(quarter from fi.order_date) as order_quarter,
    
    -- Current timestamp for refresh tracking
    current_timestamp as last_updated

from {{ ref('fact_inventory') }} fi

-- ===== DIMENSION JOINS =====
left join {{ ref('dim_drugs') }} dd 
    on fi.drug_id = dd.drug_id
left join {{ ref('dim_suppliers') }} ds 
    on fi.supplier_id = ds.supplier_id
left join {{ ref('dim_hospitals') }} dh 
    on fi.hospital_id = dh.hospital_id

-- ===== FACT TABLE JOINS =====
left join {{ ref('agg_fact_financials') }} aff 
    on fi.drug_id = aff.drug_id 
    and fi.hospital_id = aff.hospital_id

-- ===== CTE JOINS =====
left join daily_consumption dc 
    on fi.drug_id = dc.drug_id 
    and fi.hospital_id = dc.hospital_id
left join prescription_kpis pk 
    on fi.drug_id = pk.drug_id 
    and fi.hospital_id = pk.hospital_id
left join hospital_level_kpis hkpi 
    on fi.inventory_id = hkpi.inventory_id
left join supplier_level_kpis skpi 
    on fi.inventory_id = skpi.inventory_id
left join inventory_classification ic 
    on fi.inventory_id = ic.inventory_id
left join financial_metrics fm 
    on fi.inventory_id = fm.inventory_id

-- ===== FILTERS =====
where fi.current_stock_qty >= 0  -- Exclude negative stock adjustments

-- ===== ORDERING =====
order by
    ic.risk_category desc,
    hkpi.hospital_stockout_rate desc,
    fm.dead_stock_value desc,
    fi.days_to_expiry asc