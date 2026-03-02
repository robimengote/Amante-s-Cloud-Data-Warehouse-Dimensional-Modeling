-- FUNCTION 1: Main ETLT Pipeline & Quarantine Sweep
-- Description: Sweeps staging data for missing dimensions, quarantines orphans, and inserts valid records into the Star Schema idempotently.


CREATE OR REPLACE FUNCTION update_final_fact_sales()
RETURNS void AS $$
BEGIN
    -- 1. Insert valid rows into the final Star Schema
    INSERT INTO final_fact_sales (
        date_key, 
        product_id, 
        order_type_id, 
        payment_type_id, 
        order_id, 
        quantity, 
        total_order_amount, 
        total_received_amount
    )
    SELECT 
        d.date_id,
        p.product_id,
        COALESCE(ot.order_type_id, 1),
        COALESCE(pt.payment_type_id, 1),
        raw.order_id,
        CAST(raw.quantity AS INT),
        CAST(raw.total_order_amount AS DECIMAL(10,2)),
        CAST(raw.received_amount AS DECIMAL(10,2))
    FROM fact_sales2026 raw
    LEFT JOIN dim_date d ON d.full_date = raw.payment_time::DATE
    LEFT JOIN dim_product p ON p.items = raw.items 
    LEFT JOIN dim_order_type ot ON ot.order_type = raw.order_type
    LEFT JOIN dim_payment_type pt ON pt.payment_type = raw.payment_type
    WHERE NOT EXISTS (
        SELECT 1 
        FROM final_fact_sales f 
        WHERE f.order_id = raw.order_id 
          AND f.product_id = p.product_id 
    )
    AND p.product_id IS NOT NULL;

    -- 2. Sweep for orphans and push to Quarantine securely
    INSERT INTO staging_quarantine (
        order_id, items, sub_category, category, order_type, 
        total_order_amount, variation, size, quantity, 
        spice_level, sugar_level, received_amount, 
        payment_time, payment_type, flavor
    )
    SELECT 
        s.order_id, s.items, s.sub_category, s.category, s.order_type, 
        s.total_order_amount, s.variation, s.size, s.quantity, 
        s.spice_level, s.sugar_level, s.received_amount, 
        s.payment_time, s.payment_type, s.flavor
    FROM fact_sales2026 s
    LEFT JOIN dim_product p ON s.items = p.items 
    WHERE p.product_id IS NULL
    AND NOT EXISTS (
        SELECT 1 
        FROM staging_quarantine q 
        WHERE q.order_id = s.order_id 
          AND q.items = s.items
    );
    
END;
$$ LANGUAGE plpgsql;



-- FUNCTION 2: Reprocess rows inside staging_quarantine table
-- Description: Loads the quarantined rows (fixed) to the final_fact_sales table


CREATE OR REPLACE FUNCTION reprocess_quarantine()
RETURNS void AS $$
BEGIN
    -- 1. Move the now-fixed rows to the Final Fact table
    INSERT INTO final_fact_sales (
        date_key, 
        product_id, 
        order_type_id, 
        payment_type_id, 
        order_id, 
        quantity, 
        total_order_amount, 
        total_received_amount
    )
    SELECT 
        d.date_id,                       -- Maps to date_key
        p.product_id,                    -- Maps to product_id
        COALESCE(ot.order_type_id, 1),   -- Maps to order_type_id
        COALESCE(pt.payment_type_id, 1), -- Maps to payment_type_id
        q.order_id,                      -- Maps to order_id
        CAST(q.quantity AS INT),         -- Maps to quantity
        CAST(q.total_order_amount AS DECIMAL(10,2)), -- Maps to total_order_amount
        CAST(q.received_amount AS DECIMAL(10,2))     -- Maps to total_received_amount
    FROM staging_quarantine q
    -- Try to join again!
    LEFT JOIN dim_date d ON d.full_date = q.payment_time::DATE
    LEFT JOIN dim_product p ON p.items = q.items
    LEFT JOIN dim_order_type ot ON ot.order_type = q.order_type
    LEFT JOIN dim_payment_type pt ON pt.payment_type = q.payment_type
    WHERE p.product_id IS NOT NULL;

    -- 2. Delete the rows we just successfully moved
    DELETE FROM staging_quarantine q
    USING dim_product p
    WHERE q.items = p.items; 
    -- (They are removed from the ER because they found a match in the menu!)
END;
$$ LANGUAGE plpgsql;





