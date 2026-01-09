USE DataWarehouseAnalytics;
GO

/*
===============================================================================
12_report_customers
===============================================================================
Purpose:
  Customer-level reporting view built on the warehouse Gold layer (via analytics views).

Output:
  report.vw_customers

Notes:
  - Uses CREATE OR ALTER VIEW (idempotent).
  - Uses a more accurate age calculation than DATEDIFF(YEAR, ...).
===============================================================================
*/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'report')
    EXEC(N'CREATE SCHEMA report');
GO

CREATE OR ALTER VIEW report.vw_customers
AS
WITH base_query AS (
    SELECT
        f.order_number,
        f.product_sk,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_sk,
        c.customer_id,
        c.customer_key,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.birthdate
    FROM analytics_gold.vw_fact_sales f
    LEFT JOIN analytics_gold.vw_dim_customers c
        ON c.customer_sk = f.customer_sk
    WHERE f.order_date IS NOT NULL
),
customer_aggregation AS (
    SELECT
        customer_sk,
        customer_id,
        customer_key,
        customer_name,
        birthdate,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(CAST(sales_amount AS DECIMAL(18,2))) AS total_sales,
        SUM(CAST(quantity AS DECIMAL(18,2)))     AS total_quantity,
        COUNT(DISTINCT product_sk)               AS total_products,
        MAX(order_date) AS last_order_date,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan_months
    FROM base_query
    GROUP BY
        customer_sk, customer_id, customer_key, customer_name, birthdate
),
final AS (
    SELECT
        customer_sk,
        customer_id,
        customer_key,
        customer_name,
        birthdate,
        -- Accurate age: subtract 1 if birthday hasn't occurred this year
        CASE
            WHEN birthdate IS NULL THEN NULL
            ELSE DATEDIFF(YEAR, birthdate, CAST(GETDATE() AS DATE))
                 - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, birthdate, CAST(GETDATE() AS DATE)), birthdate) > CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END
        END AS age,
        last_order_date,
        DATEDIFF(MONTH, last_order_date, CAST(GETDATE() AS DATE)) AS recency_months,
        total_orders,
        total_sales,
        total_quantity,
        total_products,
        lifespan_months,
        CASE
            WHEN total_orders = 0 THEN 0
            ELSE total_sales / NULLIF(total_orders, 0)
        END AS avg_order_value,
        CASE
            WHEN lifespan_months <= 0 THEN total_sales
            ELSE total_sales / NULLIF(lifespan_months, 0)
        END AS avg_monthly_spend
    FROM customer_aggregation
)
SELECT
    customer_sk,
    customer_id,
    customer_key,
    customer_name,
    age,
    CASE
        WHEN age IS NULL THEN 'Unknown'
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50+'
    END AS age_group,
    CASE
        WHEN lifespan_months >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan_months >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,
    last_order_date,
    recency_months,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan_months,
    avg_order_value,
    avg_monthly_spend
FROM final;
GO
