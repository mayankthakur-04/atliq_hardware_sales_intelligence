-- AtliQ Hardware Sales Intelligence
-- SQL Views for Power BI Data Layer
-- Author: Mayank

USE sales;

-- ─────────────────────────────────────
-- View 1: Main Fact Table
-- Filters: INR currency, India only
-- ─────────────────────────────────────
CREATE VIEW v_india_transactions AS
SELECT 
    t.*,
    c.custmer_name,
    c.customer_type,
    m.markets_name,
    m.zone,
    p.product_type
FROM transactions t
JOIN customers c ON t.customer_code = c.customer_code
JOIN markets   m ON t.market_code   = m.markets_code
JOIN products  p ON t.product_code  = p.product_code
WHERE t.currency = 'INR'
AND m.zone != '';

-- ─────────────────────────────────────
-- View 2: Monthly Revenue Summary
-- ─────────────────────────────────────
CREATE VIEW v_monthly_revenue AS
SELECT 
    YEAR(order_date)                AS year,
    MONTH(order_date)               AS month_num,
    MONTHNAME(order_date)           AS month_name,
    m.zone,
    m.markets_name,
    SUM(t.sales_amount)             AS total_revenue,
    SUM(t.profit_margin)            AS total_profit,
    SUM(t.qty)                      AS total_qty,
    COUNT(*)                        AS total_orders,
    AVG(t.profit_margin_percentage) AS avg_profit_pct
FROM transactions t
JOIN markets m ON t.market_code = m.markets_code
WHERE t.currency = 'INR'
AND m.zone != ''
GROUP BY 1,2,3,4,5;

-- ─────────────────────────────────────
-- View 3: Customer Performance
-- ─────────────────────────────────────
CREATE VIEW v_customer_performance AS
SELECT 
    c.custmer_name    AS customer_name,
    c.customer_type,
    m.markets_name,
    m.zone,
    SUM(t.sales_amount)   AS total_revenue,
    SUM(t.profit_margin)  AS total_profit,
    SUM(t.qty)            AS total_qty,
    COUNT(*)              AS total_orders,
    ROUND(SUM(t.profit_margin) / 
          NULLIF(SUM(t.sales_amount),0) * 100, 2) 
                          AS profit_margin_pct,
    ROUND(SUM(t.sales_amount) / 
          COUNT(DISTINCT t.order_date), 2)         
                          AS avg_daily_revenue
FROM transactions t
JOIN customers c ON t.customer_code = c.customer_code
JOIN markets   m ON t.market_code   = m.markets_code
WHERE t.currency = 'INR'
AND m.zone != ''
GROUP BY 1,2,3,4;

-- ─────────────────────────────────────
-- View 4: Product Performance
-- ─────────────────────────────────────
CREATE VIEW v_product_performance AS
SELECT 
    p.product_code,
    p.product_type,
    SUM(t.sales_amount)   AS total_revenue,
    SUM(t.profit_margin)  AS total_profit,
    SUM(t.qty)            AS total_qty,
    COUNT(*)              AS total_orders,
    ROUND(SUM(t.profit_margin) /
          NULLIF(SUM(t.sales_amount),0) * 100, 2) 
                          AS profit_margin_pct
FROM transactions t
JOIN products p ON t.product_code = p.product_code
WHERE t.currency = 'INR'
GROUP BY 1,2;

-- ─────────────────────────────────────
-- View 5: YoY Revenue Comparison
-- ─────────────────────────────────────
CREATE VIEW v_yoy_comparison AS
SELECT
    m.markets_name,
    m.zone,
    SUM(CASE WHEN YEAR(order_date) = 2017 
        THEN sales_amount ELSE 0 END) AS revenue_2017,
    SUM(CASE WHEN YEAR(order_date) = 2018 
        THEN sales_amount ELSE 0 END) AS revenue_2018,
    SUM(CASE WHEN YEAR(order_date) = 2019 
        THEN sales_amount ELSE 0 END) AS revenue_2019,
    SUM(CASE WHEN YEAR(order_date) = 2020 
        THEN sales_amount ELSE 0 END) AS revenue_2020
FROM transactions t
JOIN markets m ON t.market_code = m.markets_code
WHERE t.currency = 'INR'
AND m.zone != ''
GROUP BY 1,2;