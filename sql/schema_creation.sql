/* =======================================================================
   AMANTE'S COFFEE - DIMENSIONAL MODEL SCHEMA DEFINITIONS
   ======================================================================= */

-- 1. PRODUCT DIMENSION
CREATE TABLE dim_product (
    product_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    items TEXT,
    sub_category TEXT,
    category TEXT,
    variation TEXT,
    spice_level TEXT,
    sugar_level TEXT,
    size TEXT,
    flavor TEXT
);

-- 2. DATE DIMENSION
CREATE TABLE dim_date (
    date_id INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day_name TEXT,
    month_name TEXT,
    year INT,
    quarter INT,
    is_weekend BOOLEAN,
    is_holiday BOOLEAN DEFAULT FALSE
);

-- 3. ORDER TYPE DIMENSION
CREATE TABLE dim_order_type (
    order_type_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_type TEXT
);

-- Populate dim_order_type from raw staging data
INSERT INTO dim_order_type (order_type)
SELECT DISTINCT order_type
FROM fact_sales2026;

-- 4. PAYMENT TYPE DIMENSION
CREATE TABLE dim_payment_type (
    payment_type_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payment_type TEXT
);

-- Populate dim_payment_type from raw staging data
INSERT INTO dim_payment_type (payment_type)
SELECT DISTINCT payment_type
FROM fact_sales2026;

-- 5. QUARANTINE STAGING TABLE (ERROR REPOSITORY)
-- Note: Intentionally using TEXT/Numeric without strict constraints to catch broken rows
CREATE TABLE staging_quarantine (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id TEXT,
    items TEXT,
    sub_category TEXT,
    category TEXT,
    order_type TEXT,
    total_order_amount NUMERIC,
    variation TEXT,
    size TEXT,
    quantity FLOAT,
    spice_level TEXT,
    sugar_level TEXT,
    received_amount NUMERIC,
    payment_time TIMESTAMP,
    payment_type TEXT,
    flavor TEXT
);