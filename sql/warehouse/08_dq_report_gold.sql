/*
===============================================================================
08_dq_report_gold (REPORT-ONLY, APPEND WITH TIMESTAMP)
===============================================================================
Business Objective:
  Provide non-blocking (report-only) data quality checks suitable for a portfolio
  and for ERP-style analytics environments.

Design:
  - Creates DQ tables in the GOLD schema (if not exists)
  - Appends one row per check for each run
  - Produces a concise run summary at the end

Notes:
  - No THROW / RAISERROR. The pipeline always completes.
  - If tables are empty, percentages return 0.
===============================================================================
*/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold') EXEC('CREATE SCHEMA gold');
GO

-- =========================
-- 1) DQ tables (append-only)
-- =========================

IF OBJECT_ID('gold.dq_sales_checks', 'U') IS NULL
BEGIN
    CREATE TABLE gold.dq_sales_checks (
        dq_id            BIGINT IDENTITY(1,1) PRIMARY KEY,
        run_id           UNIQUEIDENTIFIER NOT NULL,
        run_ts           DATETIME2        NOT NULL,
        check_name       NVARCHAR(200)    NOT NULL,
        severity         NVARCHAR(10)     NOT NULL, -- INFO/WARN
        rows_checked     BIGINT           NOT NULL,
        rows_flagged     BIGINT           NOT NULL,
        percent_flagged  DECIMAL(9,4)     NOT NULL,
        notes            NVARCHAR(400)    NULL
    );
END;
GO

IF OBJECT_ID('gold.dq_customer_checks', 'U') IS NULL
BEGIN
    CREATE TABLE gold.dq_customer_checks (
        dq_id            BIGINT IDENTITY(1,1) PRIMARY KEY,
        run_id           UNIQUEIDENTIFIER NOT NULL,
        run_ts           DATETIME2        NOT NULL,
        check_name       NVARCHAR(200)    NOT NULL,
        severity         NVARCHAR(10)     NOT NULL,
        rows_checked     BIGINT           NOT NULL,
        rows_flagged     BIGINT           NOT NULL,
        percent_flagged  DECIMAL(9,4)     NOT NULL,
        notes            NVARCHAR(400)    NULL
    );
END;
GO

IF OBJECT_ID('gold.dq_product_checks', 'U') IS NULL
BEGIN
    CREATE TABLE gold.dq_product_checks (
        dq_id            BIGINT IDENTITY(1,1) PRIMARY KEY,
        run_id           UNIQUEIDENTIFIER NOT NULL,
        run_ts           DATETIME2        NOT NULL,
        check_name       NVARCHAR(200)    NOT NULL,
        severity         NVARCHAR(10)     NOT NULL,
        rows_checked     BIGINT           NOT NULL,
        rows_flagged     BIGINT           NOT NULL,
        percent_flagged  DECIMAL(9,4)     NOT NULL,
        notes            NVARCHAR(400)    NULL
    );
END;
GO

IF OBJECT_ID('gold.dq_mapping_checks', 'U') IS NULL
BEGIN
    CREATE TABLE gold.dq_mapping_checks (
        dq_id            BIGINT IDENTITY(1,1) PRIMARY KEY,
        run_id           UNIQUEIDENTIFIER NOT NULL,
        run_ts           DATETIME2        NOT NULL,
        check_name       NVARCHAR(200)    NOT NULL,
        severity         NVARCHAR(10)     NOT NULL,
        rows_checked     BIGINT           NOT NULL,
        rows_flagged     BIGINT           NOT NULL,
        percent_flagged  DECIMAL(9,4)     NOT NULL,
        notes            NVARCHAR(400)    NULL
    );
END;
GO

IF OBJECT_ID('gold.dq_summary', 'U') IS NULL
BEGIN
    CREATE TABLE gold.dq_summary (
        dq_id            BIGINT IDENTITY(1,1) PRIMARY KEY,
        run_id           UNIQUEIDENTIFIER NOT NULL,
        run_ts           DATETIME2        NOT NULL,
        check_area       NVARCHAR(50)     NOT NULL, -- sales/customers/products/mapping
        rows_checked     BIGINT           NOT NULL,
        rows_flagged     BIGINT           NOT NULL,
        percent_flagged  DECIMAL(9,4)     NOT NULL,
        status           NVARCHAR(10)     NOT NULL  -- OK/WARN
    );
END;
GO

-- =========================
-- 2) Insert check results
-- =========================

DECLARE @run_id UNIQUEIDENTIFIER = NEWID();
DECLARE @run_ts DATETIME2 = SYSDATETIME();

-- Totals
DECLARE @sales_total BIGINT = (SELECT COUNT_BIG(*) FROM gold.fact_sales);
DECLARE @cust_total  BIGINT = (SELECT COUNT_BIG(*) FROM gold.dim_customers);
DECLARE @prod_total  BIGINT = (SELECT COUNT_BIG(*) FROM gold.dim_products);
DECLARE @rej_total   BIGINT = (SELECT COUNT_BIG(*) FROM gold.fact_sales_rejects);
DECLARE @attempt_total BIGINT = @sales_total + @rej_total;

DECLARE @tolerance DECIMAL(18,2) = 0.05; -- currency tolerance for sales vs qty*price

-- Helper: percent calculation
-- (Inline CASE used in each insert to avoid scalar UDF.)

/* =========================
   SALES CHECKS (gold.fact_sales)
   ========================= */

-- 1) Non-positive quantity
INSERT INTO gold.dq_sales_checks (run_id, run_ts, check_name, severity, rows_checked, rows_flagged, percent_flagged, notes)
SELECT
    @run_id, @run_ts,
    'Quantity <= 0' AS check_name,
    'WARN' AS severity,
    @sales_total AS rows_checked,
    COUNT_BIG(*) AS rows_flagged,
    CASE WHEN @sales_total = 0 THEN 0 ELSE CAST(100.0 * COUNT_BIG(*) / @sales_total AS DECIMAL(9,4)) END AS percent_flagged,
    'Quantity should be positive for sales rows.' AS notes
FROM gold.fact_sales
WHERE quantity IS NOT NULL AND quantity <= 0;

-- 2) Negative price
INSERT INTO gold.dq_sales_checks
SELECT
    @run_id, @run_ts,
    'Price < 0',
    'WARN',
    @sales_total,
    COUNT_BIG(*),
    CASE WHEN @sales_total = 0 THEN 0 ELSE CAST(100.0 * COUNT_BIG(*) / @sales_total AS DECIMAL(9,4)) END,
    'Price should not be negative.'
FROM gold.fact_sales
WHERE price IS NOT NULL AND price < 0;

-- 3) Negative sales amount
INSERT INTO gold.dq_sales_checks
SELECT
    @run_id, @run_ts,
    'Sales amount < 0',
    'WARN',
    @sales_total,
    COUNT_BIG(*),
    CASE WHEN @sales_total = 0 THEN 0 ELSE CAST(100.0 * COUNT_BIG(*) / @sales_total AS DECIMAL(9,4)) END,
    'Sales amount should not be negative.'
FROM gold.fact_sales
WHERE sales_amount IS NOT NULL AND sales_amount < 0;

-- 4) Sales amount variance vs qty*price (tolerance)
INSERT INTO gold.dq_sales_checks
SELECT
    @run_id, @run_ts,
    'Sales amount variance vs quantity*price',
    'WARN',
    @sales_total,
    COUNT_BIG(*),
    CASE WHEN @sales_total = 0 THEN 0 ELSE CAST(100.0 * COUNT_BIG(*) / @sales_total AS DECIMAL(9,4)) END,
    CONCAT('Flagged where ABS(sales_amount - quantity*price) > ', CAST(@tolerance AS NVARCHAR(50))) AS notes
FROM gold.fact_sales
WHERE sales_amount IS NOT NULL
  AND quantity IS NOT NULL
  AND price IS NOT NULL
  AND ABS(sales_amount - (CAST(quantity AS DECIMAL(18,2)) * price)) > @tolerance;

-- 5) Date sequencing issues
INSERT INTO gold.dq_sales_checks
SELECT
    @run_id, @run_ts,
    'Order date after shipping date',
    'WARN',
    @sales_total,
    COUNT_BIG(*),
    CASE WHEN @sales_total = 0 THEN 0 ELSE CAST(100.0 * COUNT_BIG(*) / @sales_total AS DECIMAL(9,4)) END,
    'order_date should be <= shipping_date (if both exist).'
FROM gold.fact_sales
WHERE order_date IS NOT NULL AND shipping_date IS NOT NULL
  AND order_date > shipping_date;

INSERT INTO gold.dq_sales_checks
SELECT
    @run_id, @run_ts,
    'Shipping date after due date',
    'INFO',
    @sales_total,
    COUNT_BIG(*),
    CASE WHEN @sales_total = 0 THEN 0 ELSE CAST(100.0 * COUNT_BIG(*) / @sales_total AS DECIMAL(9,4)) END,
    'shipping_date is typically <= due_date; review business rules.'
FROM gold.fact_sales
WHERE shipping_date IS NOT NULL AND due_date IS NOT NULL
  AND shipping_date > due_date;

-- 6) Future-dated orders (flag only)
INSERT INTO gold.dq_sales_checks
SELECT
    @run_id, @run_ts,
    'Order date in the future',
    'INFO',
    @sales_total,
    COUNT_BIG(*),
    CASE WHEN @sales_total = 0 THEN 0 ELSE CAST(100.0 * COUNT_BIG(*) / @sales_total AS DECIMAL(9,4)) END,
    'Future dates may indicate source issues or timezone/date parsing.'
FROM gold.fact_sales
WHERE order_date IS NOT NULL
  AND order_date > CAST(GETDATE() AS DATE);

 /* =========================
    CUSTOMER CHECKS (gold.dim_customers)
    ========================= */

-- 1) Duplicate business keys (customer_key)
INSERT INTO gold.dq_customer_checks
SELECT
    @run_id, @run_ts,
    'Duplicate customer_key in dim_customers',
    'WARN',
    @cust_total,
    SUM(CAST(dup_cnt AS BIGINT)) AS rows_flagged,
    CASE WHEN @cust_total = 0 THEN 0 ELSE CAST(100.0 * SUM(CAST(dup_cnt AS BIGINT)) / @cust_total AS DECIMAL(9,4)) END,
    'customer_key should be unique in the dimension.'
FROM (
    SELECT (COUNT_BIG(*) - 1) AS dup_cnt
    FROM gold.dim_customers
    GROUP BY customer_key
    HAVING COUNT_BIG(*) > 1
) d;

-- 2) Missing ERP enrichment (country)
INSERT INTO gold.dq_customer_checks
SELECT
    @run_id, @run_ts,
    'Missing customer country (ERP enrichment)',
    'INFO',
    @cust_total,
    COUNT_BIG(*),
    CASE WHEN @cust_total = 0 THEN 0 ELSE CAST(100.0 * COUNT_BIG(*) / @cust_total AS DECIMAL(9,4)) END,
    'Country enrichment missing for some customers.'
FROM gold.dim_customers
WHERE (country IS NULL OR LTRIM(RTRIM(country)) = '');

-- 3) Customers with no sales
INSERT INTO gold.dq_customer_checks
SELECT
    @run_id, @run_ts,
    'Customers with no sales',
    'INFO',
    @cust_total,
    COUNT_BIG(*),
    CASE WHEN @cust_total = 0 THEN 0 ELSE CAST(100.0 * COUNT_BIG(*) / @cust_total AS DECIMAL(9,4)) END,
    'Useful for understanding active vs inactive accounts.'
FROM gold.dim_customers c
LEFT JOIN gold.fact_sales f ON f.customer_sk = c.customer_sk
WHERE f.customer_sk IS NULL;

 /* =========================
    PRODUCT CHECKS (gold.dim_products)
    ========================= */

-- 1) Duplicate product_key in dim_products
INSERT INTO gold.dq_product_checks
SELECT
    @run_id, @run_ts,
    'Duplicate product_key in dim_products',
    'WARN',
    @prod_total,
    SUM(CAST(dup_cnt AS BIGINT)),
    CASE WHEN @prod_total = 0 THEN 0 ELSE CAST(100.0 * SUM(CAST(dup_cnt AS BIGINT)) / @prod_total AS DECIMAL(9,4)) END,
    'product_key should be unique in the dimension.'
FROM (
    SELECT (COUNT_BIG(*) - 1) AS dup_cnt
    FROM gold.dim_products
    GROUP BY product_key
    HAVING COUNT_BIG(*) > 1
) d;

-- 2) Missing product category enrichment
INSERT INTO gold.dq_product_checks
SELECT
    @run_id, @run_ts,
    'Missing product category (ERP mapping)',
    'INFO',
    @prod_total,
    COUNT_BIG(*),
    CASE WHEN @prod_total = 0 THEN 0 ELSE CAST(100.0 * COUNT_BIG(*) / @prod_total AS DECIMAL(9,4)) END,
    'CAT/SUBCAT enrichment missing for some products.'
FROM gold.dim_products
WHERE (category IS NULL OR LTRIM(RTRIM(category)) = '');

-- 3) Products never sold
INSERT INTO gold.dq_product_checks
SELECT
    @run_id, @run_ts,
    'Products never sold',
    'INFO',
    @prod_total,
    COUNT_BIG(*),
    CASE WHEN @prod_total = 0 THEN 0 ELSE CAST(100.0 * COUNT_BIG(*) / @prod_total AS DECIMAL(9,4)) END,
    'Useful for catalogue health and inventory rationalisation.'
FROM gold.dim_products p
LEFT JOIN gold.fact_sales f ON f.product_sk = p.product_sk
WHERE f.product_sk IS NULL;

 /* =========================
    MAPPING CHECKS (gold.fact_sales_rejects)
    ========================= */

-- 1) Any rejects (overall)
INSERT INTO gold.dq_mapping_checks
SELECT
    @run_id, @run_ts,
    'Rejected sales rows (unmapped customer/product)',
    CASE WHEN COUNT_BIG(*) = 0 THEN 'INFO' ELSE 'WARN' END,
    @attempt_total,
    @rej_total,
    CASE WHEN @attempt_total = 0 THEN 0 ELSE CAST(100.0 * @rej_total / @attempt_total AS DECIMAL(9,4)) END,
    'Rows rejected during fact load due to missing dimension mappings.'
;

-- 2) Rejects by reason
INSERT INTO gold.dq_mapping_checks
SELECT
    @run_id, @run_ts,
    CONCAT('Reject reason: ', reject_reason) AS check_name,
    'WARN',
    @attempt_total,
    COUNT_BIG(*) AS rows_flagged,
    CASE WHEN @attempt_total = 0 THEN 0 ELSE CAST(100.0 * COUNT_BIG(*) / @attempt_total AS DECIMAL(9,4)) END,
    NULL
FROM gold.fact_sales_rejects
GROUP BY reject_reason;

-- =========================
-- 3) Run-level summary
-- =========================

;WITH sales_bad AS (
    SELECT DISTINCT fact_sales_sk
    FROM gold.fact_sales
    WHERE (quantity IS NOT NULL AND quantity <= 0)
       OR (price IS NOT NULL AND price < 0)
       OR (sales_amount IS NOT NULL AND sales_amount < 0)
       OR (
            sales_amount IS NOT NULL AND quantity IS NOT NULL AND price IS NOT NULL
            AND ABS(sales_amount - (CAST(quantity AS DECIMAL(18,2)) * price)) > @tolerance
          )
       OR (order_date IS NOT NULL AND shipping_date IS NOT NULL AND order_date > shipping_date)
),
cust_bad AS (
    SELECT DISTINCT c.customer_sk
    FROM gold.dim_customers c
    WHERE (c.country IS NULL OR LTRIM(RTRIM(c.country)) = '')
),
prod_bad AS (
    SELECT DISTINCT p.product_sk
    FROM gold.dim_products p
    WHERE (p.category IS NULL OR LTRIM(RTRIM(p.category)) = '')
)
INSERT INTO gold.dq_summary (run_id, run_ts, check_area, rows_checked, rows_flagged, percent_flagged, status)
SELECT
    @run_id, @run_ts, 'sales',
    @sales_total,
    (SELECT COUNT_BIG(*) FROM sales_bad),
    CASE WHEN @sales_total = 0 THEN 0 ELSE CAST(100.0 * (SELECT COUNT_BIG(*) FROM sales_bad) / @sales_total AS DECIMAL(9,4)) END,
    CASE WHEN (SELECT COUNT_BIG(*) FROM sales_bad) = 0 THEN 'OK' ELSE 'WARN' END
UNION ALL
SELECT
    @run_id, @run_ts, 'customers',
    @cust_total,
    (SELECT COUNT_BIG(*) FROM cust_bad),
    CASE WHEN @cust_total = 0 THEN 0 ELSE CAST(100.0 * (SELECT COUNT_BIG(*) FROM cust_bad) / @cust_total AS DECIMAL(9,4)) END,
    CASE WHEN (SELECT COUNT_BIG(*) FROM cust_bad) = 0 THEN 'OK' ELSE 'WARN' END
UNION ALL
SELECT
    @run_id, @run_ts, 'products',
    @prod_total,
    (SELECT COUNT_BIG(*) FROM prod_bad),
    CASE WHEN @prod_total = 0 THEN 0 ELSE CAST(100.0 * (SELECT COUNT_BIG(*) FROM prod_bad) / @prod_total AS DECIMAL(9,4)) END,
    CASE WHEN (SELECT COUNT_BIG(*) FROM prod_bad) = 0 THEN 'OK' ELSE 'WARN' END
UNION ALL
SELECT
    @run_id, @run_ts, 'mapping',
    @attempt_total,
    @rej_total,
    CASE WHEN @attempt_total = 0 THEN 0 ELSE CAST(100.0 * @rej_total / @attempt_total AS DECIMAL(9,4)) END,
    CASE WHEN @rej_total = 0 THEN 'OK' ELSE 'WARN' END
;

-- =========================
-- 4) Display latest summary
-- =========================
PRINT 'DQ summary (latest run):';
SELECT *
FROM gold.dq_summary
WHERE run_id = @run_id
ORDER BY check_area;

PRINT 'Top DQ checks (latest run):';

SELECT TOP (25) *
FROM gold.dq_sales_checks
WHERE run_id = @run_id
ORDER BY rows_flagged DESC, check_name;

SELECT TOP (25) *
FROM gold.dq_mapping_checks
WHERE run_id = @run_id
ORDER BY rows_flagged DESC, check_name;
GO
