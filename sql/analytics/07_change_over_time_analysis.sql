USE DataWarehouseAnalytics;
GO

/*
===============================================================================
07_change_over_time_analysis
===============================================================================
Purpose:
  Trend analysis over time (monthly rollups).

Industry notes:
  - Uses DATEFROMPARTS for month bucketing (compatible with SQL Server 2012+).
  - Avoids FORMAT() for grouping/sorting performance reasons.
===============================================================================
*/

-- Monthly sales, customers and quantity
SELECT
    DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS month_start,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM analytics_gold.vw_fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
ORDER BY month_start;
