USE DataWarehouseAnalytics;
GO

/*
===============================================================================
13_report_products
===============================================================================
Purpose:
  Product-level reporting view built on the warehouse Gold layer (via analytics views).

Output:
  report.vw_products
===============================================================================
*/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'report')
    EXEC(N'CREATE SCHEMA report');
GO

CREATE OR ALTER VIEW report.vw_products
AS
WITH base_query AS (
    SELECT
        f.order_number,
        f.order_date,
        f.customer_sk,
        f.sales_amount,
        f.quantity,
        p.product_sk,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM analytics_gold.vw_fact_sales f
    LEFT JOIN analytics_gold.vw_dim_products p
        ON p.product_sk = f.product_sk
    WHERE f.order_date IS NOT NULL
),
product_aggregation AS (
    SELECT
        product_sk,
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan_months,
        MAX(order_date) AS last_sale_date,
        COUNT(DISTINCT order_number) AS total_orders,
        COUNT(DISTINCT customer_sk)  AS total_customers,
        SUM(CAST(sales_amount AS DECIMAL(18,2))) AS total_sales,
        SUM(CAST(quantity AS DECIMAL(18,2)))     AS total_quantity,
        ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 2) AS avg_selling_price
    FROM base_query
    GROUP BY
        product_sk, product_key, product_name, category, subcategory, cost
)
SELECT
    product_sk,
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    DATEDIFF(MONTH, last_sale_date, CAST(GETDATE() AS DATE)) AS recency_months,
    CASE
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segment,
    lifespan_months,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / NULLIF(total_orders, 0)
    END AS avg_order_revenue,
    CASE
        WHEN lifespan_months <= 0 THEN total_sales
        ELSE total_sales / NULLIF(lifespan_months, 0)
    END AS avg_monthly_revenue
FROM product_aggregation;
GO
