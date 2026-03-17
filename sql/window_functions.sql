-- Q6: Running total of sales per year
WITH monthly AS (
    SELECT
        substr(order_date, -4)                  AS year,
        CASE
            WHEN substr(order_date, 2, 1) = '/'
            THEN '0' || substr(order_date, 1, 1)
            ELSE substr(order_date, 1, 2)
        END                                     AS month,
        ROUND(SUM(sales), 2)                    AS monthly_sales
    FROM orders
    GROUP BY year, month
)
SELECT
    year,
    month,
    monthly_sales,
    ROUND(SUM(monthly_sales) OVER (
        PARTITION BY year
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2)                                       AS running_total
FROM monthly
ORDER BY year, month;

-- Q7: Rank customers by sales within each segment
SELECT
    customer_name,
    segment,
    ROUND(SUM(sales), 2) AS total_sales,
    RANK() OVER (
        PARTITION BY segment
        ORDER BY SUM(sales) DESC
    ) AS rank_in_segment
FROM orders
GROUP BY customer_name, segment
ORDER BY segment, rank_in_segment
LIMIT 30;

-- Q8: Month-over-month sales growth %
WITH monthly AS (
    SELECT
        substr(order_date, -4) || '-' ||
        CASE
            WHEN substr(order_date, 2, 1) = '/'
            THEN '0' || substr(order_date, 1, 1)
            ELSE substr(order_date, 1, 2)
        END                                     AS year_month,
        ROUND(SUM(sales), 2)                    AS monthly_sales
    FROM orders
    GROUP BY year_month
)
SELECT
    year_month,
    monthly_sales,
    LAG(monthly_sales) OVER (ORDER BY year_month)   AS prev_month_sales,
    ROUND(
        (monthly_sales - LAG(monthly_sales) OVER (ORDER BY year_month))
        / LAG(monthly_sales) OVER (ORDER BY year_month) * 100, 2
    )                                               AS mom_growth_pct
FROM monthly
ORDER BY year_month;

-- Q9: 3-month moving average of sales
WITH monthly AS (
    SELECT
        substr(order_date, -4) || '-' ||
        CASE
            WHEN substr(order_date, 2, 1) = '/'
            THEN '0' || substr(order_date, 1, 1)
            ELSE substr(order_date, 1, 2)
        END                                     AS year_month,
        ROUND(SUM(sales), 2)                    AS monthly_sales
    FROM orders
    GROUP BY year_month
)
SELECT
    year_month,
    monthly_sales,
    ROUND(AVG(monthly_sales) OVER (
        ORDER BY year_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                       AS moving_avg_3m
FROM monthly
ORDER BY year_month;

-- Q10: % contribution of each sub-category to total sales
SELECT
    category,
    sub_category,
    ROUND(SUM(sales), 2)                                        AS sub_cat_sales,
    ROUND(
        SUM(sales) * 100.0 / SUM(SUM(sales)) OVER (), 2
    )                                                           AS pct_of_total
FROM orders
GROUP BY category, sub_category
ORDER BY pct_of_total DESC;

-- Q11: Loss-making orders by discount band
SELECT
    CASE
        WHEN discount = 0                   THEN 'No discount'
        WHEN discount BETWEEN 0.01 AND 0.2  THEN '1-20%'
        WHEN discount BETWEEN 0.21 AND 0.4  THEN '21-40%'
        ELSE 'Over 40%'
    END                             AS discount_band,
    COUNT(*)                        AS order_count,
    ROUND(SUM(sales), 2)            AS total_sales,
    ROUND(SUM(profit), 2)           AS total_profit,
    ROUND(AVG(profit), 2)           AS avg_profit_per_order
FROM orders
GROUP BY discount_band
ORDER BY avg_profit_per_order;

-- Q12: Average days to ship by ship mode
SELECT
    ship_mode,
    COUNT(*)                                                        AS total_orders,
    ROUND(AVG(
        julianday(substr(ship_date, -4) || '-' ||
        CASE
            WHEN substr(ship_date, 2,1)='/'
            THEN '0'||substr(ship_date,1,1)
            ELSE substr(ship_date,1,2)
        END || '-' ||
        CASE
            WHEN substr(ship_date, 2,1)='/'
            THEN substr(ship_date, 4,2)
            ELSE substr(ship_date, 4,2)
        END)
        -
        julianday(substr(order_date, -4) || '-' ||
        CASE
            WHEN substr(order_date, 2,1)='/'
            THEN '0'||substr(order_date,1,1)
            ELSE substr(order_date,1,2)
        END || '-' ||
        CASE
            WHEN substr(order_date, 2,1)='/'
            THEN substr(order_date, 4,2)
            ELSE substr(order_date, 4,2)
        END)
    ), 1)                                                           AS avg_days_to_ship,
    MIN(julianday(ship_date) - julianday(order_date))               AS min_days,
    MAX(julianday(ship_date) - julianday(order_date))               AS max_days
FROM orders
GROUP BY ship_mode
ORDER BY avg_days_to_ship;

-- Q13: Top state by profit in each region
WITH state_profits AS (
    SELECT
        region,
        state,
        ROUND(SUM(profit), 2)   AS total_profit,
        RANK() OVER (
            PARTITION BY region
            ORDER BY SUM(profit) DESC
        )                       AS rank_in_region
    FROM orders
    GROUP BY region, state
)
SELECT region, state, total_profit
FROM state_profits
WHERE rank_in_region = 1
ORDER BY total_profit DESC;

-- Q14: Repeat vs one-time customers
SELECT
    CASE
        WHEN order_count = 1        THEN 'One-time'
        WHEN order_count BETWEEN 2 AND 5 THEN 'Repeat (2-5)'
        ELSE 'Loyal (6+)'
    END                             AS customer_type,
    COUNT(*)                        AS customer_count,
    ROUND(AVG(total_spent), 2)      AS avg_spend
FROM (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id)    AS order_count,
        SUM(sales)                  AS total_spent
    FROM orders
    GROUP BY customer_id
) sub
GROUP BY customer_type
ORDER BY avg_spend DESC;

-- Q15: Year-over-year sales growth by category
WITH yearly AS (
    SELECT
        substr(order_date, -4)          AS year,
        category,
        ROUND(SUM(sales), 2)            AS yearly_sales
    FROM orders
    GROUP BY year, category
)
SELECT
    year,
    category,
    yearly_sales,
    LAG(yearly_sales) OVER (
        PARTITION BY category
        ORDER BY year
    )                                   AS prev_year_sales,
    ROUND(
        (yearly_sales - LAG(yearly_sales) OVER (
            PARTITION BY category ORDER BY year)
        ) / LAG(yearly_sales) OVER (
            PARTITION BY category ORDER BY year
        ) * 100, 1
    )                                   AS yoy_growth_pct
FROM yearly
ORDER BY category, year;