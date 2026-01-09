/*
===============================================================================
05_proc_load_gold
===============================================================================
Purpose:
  Build GOLD dimension and fact TABLES from SILVER, with:
    - Surrogate keys in dimensions
    - Fact references dimensions via FKs
    - Reject handling for unmapped customer/product records

Run order:
  After Silver load and Silver quality checks.
===============================================================================
*/
USE DataWarehouse;
GO 

CREATE OR ALTER PROCEDURE dbo.proc_load_gold
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @start_time DATETIME2 = SYSDATETIME();
    DECLARE @end_time   DATETIME2;

    BEGIN TRY
        -- clean target
        TRUNCATE TABLE gold.fact_sales_rejects;
        TRUNCATE TABLE gold.fact_sales;

        -- reload dimensions (truncate + insert keeps surrogate keys stable only within a run)
        TRUNCATE TABLE gold.dim_products;
        TRUNCATE TABLE gold.dim_customers;

        /*-------------------------------------------------------------------
        Dim Customers (ERP enrichment by cst_key)
        -------------------------------------------------------------------*/
        INSERT INTO gold.dim_customers (
            customer_id, customer_key, first_name, last_name,
            marital_status, gender, birthdate, country, create_date
        )
        SELECT
            ci.cst_id            AS customer_id,
            ci.cst_key           AS customer_key,
            ci.cst_firstname     AS first_name,
            ci.cst_lastname      AS last_name,
            ci.cst_marital_status AS marital_status,
            ci.cst_gender        AS gender,
            az.bdate             AS birthdate,
            loc.cntry            AS country,
            ci.cst_create_date   AS create_date
        FROM silver.crm_cust_info ci
        LEFT JOIN silver.erp_cust_az12 az
            ON az.cid = ci.cst_key
        LEFT JOIN silver.erp_loc_a101 loc
            ON loc.cid = ci.cst_key
        WHERE ci.cst_id IS NOT NULL AND ci.cst_key IS NOT NULL;

        /*-------------------------------------------------------------------
        Dim Products
          - Keep the latest record per canonical product_key for reporting
        -------------------------------------------------------------------*/
        ;WITH latest_product AS (
            SELECT
                p.*,
                ROW_NUMBER() OVER (PARTITION BY p.prd_key ORDER BY p.prd_start_dt DESC, p.prd_id DESC) AS rn
            FROM silver.crm_prd_info p
            WHERE p.prd_key IS NOT NULL
        )
        INSERT INTO gold.dim_products (
            product_key, product_id, product_name,
            category_id, category, subcategory, maintenance,
            cost, product_line, start_date, end_date
        )
        SELECT
            p.prd_key        AS product_key,
            p.prd_id         AS product_id,
            p.prd_nm         AS product_name,
            p.cat_id         AS category_id,
            cat.cat          AS category,
            cat.subcat       AS subcategory,
            cat.maintenance  AS maintenance,
            p.prd_cost       AS cost,
            p.prd_line       AS product_line,
            p.prd_start_dt   AS start_date,
            p.prd_end_dt     AS end_date
        FROM latest_product p
        LEFT JOIN silver.erp_px_cat_g1v2 cat
            ON cat.id = p.cat_id
        WHERE p.rn = 1;

        /*-------------------------------------------------------------------
        Fact Sales
          - Map customer_id -> customer_key via dim_customers
          - Ensure product_key exists in dim_products
          - Reject unmapped rows for transparency
        -------------------------------------------------------------------*/
        -- 1) Rejects: unmapped customer or product
        INSERT INTO gold.fact_sales_rejects (
            order_number, order_date, shipping_date, due_date,
            sales_amount, quantity, price,
            customer_id, product_key_raw, reject_reason
        )
        SELECT
            s.sls_ord_num,
            s.sls_order_dt,
            s.sls_ship_dt,
            s.sls_due_dt,
            s.sls_sales,
            s.sls_quantity,
            s.sls_price,
            s.sls_cust_id,
            s.sls_prd_key,
            CONCAT(
                CASE WHEN c.customer_sk IS NULL THEN 'Unmapped customer_id; ' ELSE '' END,
                CASE WHEN p.product_sk  IS NULL THEN 'Unmapped product_key; ' ELSE '' END
            ) AS reject_reason
        FROM silver.crm_sales_details s
        LEFT JOIN gold.dim_customers c
            ON c.customer_id = s.sls_cust_id
        LEFT JOIN gold.dim_products p
            ON p.product_key = s.sls_prd_key
        WHERE c.customer_sk IS NULL OR p.product_sk IS NULL;

        -- 2) Insert only mapped rows into fact (FK-safe)
        INSERT INTO gold.fact_sales (
            order_number, order_date, shipping_date, due_date,
            sales_amount, quantity, price,
            customer_key, product_key,
            customer_sk, product_sk
        )
        SELECT
            s.sls_ord_num,
            s.sls_order_dt,
            s.sls_ship_dt,
            s.sls_due_dt,
            s.sls_sales,
            s.sls_quantity,
            s.sls_price,
            c.customer_key,
            p.product_key,
            c.customer_sk,
            p.product_sk
        FROM silver.crm_sales_details s
        INNER JOIN gold.dim_customers c
            ON c.customer_id = s.sls_cust_id
        INNER JOIN gold.dim_products p
            ON p.product_key = s.sls_prd_key;

        SET @end_time = SYSDATETIME();

        DECLARE @fact_rows   BIGINT;
        DECLARE @reject_rows BIGINT;

        SELECT @fact_rows = COUNT_BIG(*) FROM gold.fact_sales;
        SELECT @reject_rows = COUNT_BIG(*) FROM gold.fact_sales_rejects;

        PRINT CONCAT('Gold load complete. Duration (sec): ', DATEDIFF(SECOND, @start_time, @end_time));
        PRINT CONCAT('Gold fact rows: ', @fact_rows);
        PRINT CONCAT('Gold reject rows: ', @reject_rows);

    END TRY
    BEGIN CATCH
        SET @end_time = SYSDATETIME();
        PRINT CONCAT('Gold load failed after (sec): ', DATEDIFF(SECOND, @start_time, @end_time));
        THROW;
    END CATCH
END;
GO
