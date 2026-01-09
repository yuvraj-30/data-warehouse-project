USE DataWarehouseAnalytics;
GO

/*
===============================================================================
08_cumulative_analysis
===============================================================================
Purpose:
  Running totals and moving averages over time.

Design:
  - Monthly aggregation using DATEFROMPARTS (SQL Server 2012+).
===============================================================================
*/

WITH monthly AS (
    SELECT
        DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS month_start,
        SUM(CAST(sales_amount AS DECIMAL(18,2))) AS total_sales,
        AVG(CAST(price AS DECIMAL(18,2)))        AS avg_price
    FROM analytics_gold.vw_fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
)
SELECT
    month_start,
    total_sales,
    SUM(total_sales) OVER (ORDER BY month_start) AS running_total_sales,
    AVG(avg_price)  OVER (ORDER BY month_start)  AS moving_average_price
FROM monthly
ORDER BY month_start;
