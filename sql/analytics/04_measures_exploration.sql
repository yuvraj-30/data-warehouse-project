USE DataWarehouseAnalytics;
GO

/*
===============================================================================
04_measures_exploration
===============================================================================
Purpose:
  Compute core measures and sanity-check counts for sales, customers and products.

Source:
  analytics_gold.vw_fact_sales / vw_dim_customers / vw_dim_products
===============================================================================
*/

-- Total Sales
SELECT SUM(sales_amount) AS total_sales
FROM analytics_gold.vw_fact_sales;

-- Total Quantity
SELECT SUM(quantity) AS total_quantity
FROM analytics_gold.vw_fact_sales;

-- Average Selling Price (simple mean of price column)
SELECT AVG(price) AS avg_price
FROM analytics_gold.vw_fact_sales;

-- Orders: total rows vs distinct order numbers
SELECT COUNT_BIG(*) AS fact_rows
FROM analytics_gold.vw_fact_sales;

SELECT COUNT_BIG(DISTINCT order_number) AS distinct_orders
FROM analytics_gold.vw_fact_sales;

-- Total Products / Customers
SELECT COUNT_BIG(*) AS total_products
FROM analytics_gold.vw_dim_products;

SELECT COUNT_BIG(*) AS total_customers
FROM analytics_gold.vw_dim_customers;

-- Customers with at least one order
SELECT COUNT_BIG(DISTINCT customer_sk) AS ordering_customers
FROM analytics_gold.vw_fact_sales;

-- Consolidated KPI tile output
SELECT 'Total Sales'        AS measure_name, CAST(SUM(sales_amount) AS DECIMAL(18,2)) AS measure_value FROM analytics_gold.vw_fact_sales
UNION ALL
SELECT 'Total Quantity',    CAST(SUM(quantity)     AS DECIMAL(18,2)) FROM analytics_gold.vw_fact_sales
UNION ALL
SELECT 'Average Price',     CAST(AVG(price)        AS DECIMAL(18,2)) FROM analytics_gold.vw_fact_sales
UNION ALL
SELECT 'Total Orders',      CAST(COUNT_BIG(DISTINCT order_number) AS DECIMAL(18,2)) FROM analytics_gold.vw_fact_sales
UNION ALL
SELECT 'Total Products',    CAST(COUNT_BIG(*) AS DECIMAL(18,2)) FROM analytics_gold.vw_dim_products
UNION ALL
SELECT 'Total Customers',   CAST(COUNT_BIG(*) AS DECIMAL(18,2)) FROM analytics_gold.vw_dim_customers;
