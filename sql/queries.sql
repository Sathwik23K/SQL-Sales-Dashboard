-- Q1: Total sales, profit and orders by region
SELECT
    region,
    COUNT(DISTINCT order_id)                    AS total_orders,
    ROUND(SUM(sales), 2)                        AS total_sales,
    ROUND(SUM(profit), 2)                       AS total_profit,
    ROUND(SUM(profit)/SUM(sales)*100, 2)        AS profit_margin_pct
FROM orders
GROUP BY region
ORDER BY total_sales DESC;

-- Q2: Monthly sales trend (fully fixed)
SELECT
    substr(order_date, -4)                  AS year,
    CASE
        WHEN substr(order_date, 2, 1) = '/'
        THEN '0' || substr(order_date, 1, 1)
        ELSE substr(order_date, 1, 2)
    END                                     AS month,
    ROUND(SUM(sales), 2)                    AS monthly_sales,
    ROUND(SUM(profit), 2)                   AS monthly_profit
FROM orders
GROUP BY year, month
ORDER BY year, month;

-- Q3: Top 10 products by revenue
SELECT
    product_name,
    category,
    sub_category,
    ROUND(SUM(sales), 2)    AS total_sales,
    ROUND(SUM(profit), 2)   AS total_profit,
    COUNT(*)                AS times_ordered
FROM orders
GROUP BY product_name, category, sub_category
ORDER BY total_sales DESC
LIMIT 10;

-- Q4: Customer RFM segmentation
WITH rfm AS (
    SELECT
        customer_id,
        customer_name,
        COUNT(DISTINCT order_id)        AS frequency,
        ROUND(SUM(sales), 2)            AS monetary
    FROM orders
    GROUP BY customer_id, customer_name
),
rfm_scored AS (
    SELECT *,
        CASE
            WHEN frequency >= 10 THEN 'High'
            WHEN frequency >= 5  THEN 'Medium'
            ELSE 'Low'
        END AS freq_segment,
        CASE
            WHEN monetary >= 5000 THEN 'High Value'
            WHEN monetary >= 1000 THEN 'Mid Value'
            ELSE 'Low Value'
        END AS value_segment
    FROM rfm
)
SELECT * FROM rfm_scored
ORDER BY monetary DESC
LIMIT 20;

-- Q5: Sub-categories with above-average profit margin
WITH category_metrics AS (
    SELECT
        category,
        sub_category,
        ROUND(SUM(sales), 2)                        AS total_sales,
        ROUND(SUM(profit), 2)                       AS total_profit,
        ROUND(SUM(profit)/SUM(sales)*100, 2)        AS profit_margin
    FROM orders
    GROUP BY category, sub_category
),
avg_margin AS (
    SELECT ROUND(AVG(profit_margin), 2) AS overall_avg
    FROM category_metrics
)
SELECT
    cm.category,
    cm.sub_category,
    cm.total_sales,
    cm.total_profit,
    cm.profit_margin,
    am.overall_avg,
    ROUND(cm.profit_margin - am.overall_avg, 2)     AS margin_vs_avg
FROM category_metrics cm
CROSS JOIN avg_margin am
WHERE cm.profit_margin > am.overall_avg
ORDER BY cm.profit_margin DESC;