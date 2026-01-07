/*
===============================================================================
04_proc_load_silver
===============================================================================
Technical Objective: Clean, de-duplicate, and conform Bronze data into Silver, enabling reliable customer/product mapping.
===============================================================================
*/

/*
Purpose:
  Transform BRONZE raw tables into SILVER standardized tables.

Usage:
  EXEC silver.proc_load_silver;
*/

CREATE OR ALTER PROCEDURE silver.proc_load_silver
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @run_id INT;
    INSERT INTO dbo.etl_run_log(layer_name, procedure_name)
    VALUES (N'silver', N'silver.proc_load_silver');
    SET @run_id = SCOPE_IDENTITY();

    DECLARE @start_time DATETIME2(0) = SYSDATETIME(), @end_time DATETIME2(0);

    BEGIN TRY
        -- ===== Customers =====
        TRUNCATE TABLE silver.crm_cust_info;

        ;WITH cleaned AS (
            SELECT
                TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(cst_id)), '')) AS cst_id,
                NULLIF(LTRIM(RTRIM(cst_key)), '') AS cst_key,
                NULLIF(LTRIM(RTRIM(cst_firstname)), '') AS cst_firstname,
                NULLIF(LTRIM(RTRIM(cst_lastname)), '') AS cst_lastname,
                NULLIF(LTRIM(RTRIM(cst_marital_status)), '') AS cst_marital_status,
                NULLIF(LTRIM(RTRIM(cst_gender)), '') AS cst_gender,
                TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(cst_create_date)), '')) AS cst_create_date,
                ROW_NUMBER() OVER (
                    PARTITION BY TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(cst_id)), ''))
                    ORDER BY TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(cst_create_date)), '')) DESC
                ) AS rn
            FROM bronze.crm_cust_info
        )
        INSERT INTO silver.crm_cust_info (cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gender, cst_create_date)
        SELECT cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gender, cst_create_date
        FROM cleaned
        WHERE rn = 1 AND cst_id IS NOT NULL AND cst_key IS NOT NULL;

        -- ===== Products =====
        TRUNCATE TABLE silver.crm_prd_info;

        ;WITH base AS (
            SELECT
                TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(prd_id)), '')) AS prd_id,
                NULLIF(LTRIM(RTRIM(prd_key)), '') AS prd_key_raw,
                NULLIF(LTRIM(RTRIM(prd_nm)), '') AS prd_nm,
                TRY_CONVERT(DECIMAL(18,2), NULLIF(LTRIM(RTRIM(prd_cost)), '')) AS prd_cost,
                NULLIF(LTRIM(RTRIM(prd_line)), '') AS prd_line_raw,
                TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(prd_start_dt)), '')) AS prd_start_dt,
                TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(prd_end_dt)), '')) AS prd_end_dt_src
            FROM bronze.crm_prd_info
        ),
        parsed AS (
            SELECT
                prd_id,
                -- Category mapping key used by ERP reference table (e.g., AC_HE, CO_RF)
                CASE
                    WHEN prd_key_raw IS NULL THEN NULL
                    WHEN CHARINDEX('-', prd_key_raw) = 0 THEN NULL
                    WHEN CHARINDEX('-', prd_key_raw, CHARINDEX('-', prd_key_raw) + 1) = 0 THEN NULL
                    ELSE CONCAT(
                        LEFT(prd_key_raw, CHARINDEX('-', prd_key_raw) - 1),
                        '_',
                        SUBSTRING(
                            prd_key_raw,
                            CHARINDEX('-', prd_key_raw) + 1,
                            CHARINDEX('-', prd_key_raw, CHARINDEX('-', prd_key_raw) + 1) - CHARINDEX('-', prd_key_raw) - 1
                        )
                    )
                END AS cat_id,
                -- Canonical product key used for reporting (drops first 2 segments, e.g., CO-RF-FR-R92B-58 -> FR-R92B-58)
                CASE
                    WHEN prd_key_raw IS NULL THEN NULL
                    WHEN CHARINDEX('-', prd_key_raw) = 0 THEN NULLIF(prd_key_raw, '')
                    WHEN CHARINDEX('-', prd_key_raw, CHARINDEX('-', prd_key_raw) + 1) = 0
                        THEN RIGHT(prd_key_raw, LEN(prd_key_raw) - CHARINDEX('-', prd_key_raw))
                    ELSE SUBSTRING(
                        prd_key_raw,
                        CHARINDEX('-', prd_key_raw, CHARINDEX('-', prd_key_raw) + 1) + 1,
                        8000
                    )
                END AS prd_key,
                prd_nm,
                prd_cost,
                prd_line_raw,
                prd_start_dt,
                prd_end_dt_src
            FROM base
        ),
        mapped AS (
            SELECT
                prd_id,
                cat_id,
                prd_key,
                prd_nm,
                ISNULL(prd_cost, 0) AS prd_cost,
                CASE
                    WHEN UPPER(prd_line_raw) = 'M' THEN 'Mountain'
                    WHEN UPPER(prd_line_raw) = 'R' THEN 'Road'
                    WHEN UPPER(prd_line_raw) = 'S' THEN 'Other Sales'
                    WHEN UPPER(prd_line_raw) = 'T' THEN 'Touring'
                    WHEN prd_line_raw IS NULL THEN NULL
                    ELSE prd_line_raw
                END AS prd_line,
                prd_start_dt,
                prd_end_dt_src,
                LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) AS next_start
            FROM parsed
            WHERE prd_id IS NOT NULL AND prd_key IS NOT NULL
        )
        INSERT INTO silver.crm_prd_info (prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
        SELECT
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            COALESCE(
                prd_end_dt_src,
                CASE
                    WHEN next_start IS NULL OR prd_start_dt IS NULL THEN NULL
                    ELSE DATEADD(DAY, -1, next_start)
                END
            ) AS prd_end_dt
        FROM mapped;

        -- ===== Sales details =====
        TRUNCATE TABLE silver.crm_sales_details;

        INSERT INTO silver.crm_sales_details (
            sls_ord_num, sls_prd_key, sls_cust_id,
            sls_order_dt, sls_ship_dt, sls_due_dt,
            sls_sales, sls_quantity, sls_price
        )
        SELECT
            NULLIF(LTRIM(RTRIM(sls_ord_num)), '') AS sls_ord_num,
                        -- align with product key parsing (drops first 2 segments, e.g., CO-RF-FR-R92B-58 -> FR-R92B-58)
            CASE
                WHEN sls_prd_key IS NULL THEN NULL
                WHEN CHARINDEX('-', LTRIM(RTRIM(sls_prd_key))) = 0 THEN NULLIF(LTRIM(RTRIM(sls_prd_key)), '')
                WHEN CHARINDEX('-', LTRIM(RTRIM(sls_prd_key)), CHARINDEX('-', LTRIM(RTRIM(sls_prd_key))) + 1) = 0
                    THEN RIGHT(LTRIM(RTRIM(sls_prd_key)), LEN(LTRIM(RTRIM(sls_prd_key))) - CHARINDEX('-', LTRIM(RTRIM(sls_prd_key))))
                ELSE SUBSTRING(
                    LTRIM(RTRIM(sls_prd_key)),
                    CHARINDEX('-', LTRIM(RTRIM(sls_prd_key)), CHARINDEX('-', LTRIM(RTRIM(sls_prd_key))) + 1) + 1,
                    8000
                )
            END AS sls_prd_key,
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(sls_cust_id)), '')) AS sls_cust_id,
            TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(sls_order_dt)), '')) AS sls_order_dt,
            TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(sls_ship_dt)), '')) AS sls_ship_dt,
            TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(sls_due_dt)), ''))  AS sls_due_dt,
            TRY_CONVERT(DECIMAL(18,2), NULLIF(LTRIM(RTRIM(sls_sales)), '')) AS sls_sales,
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(sls_quantity)), '')) AS sls_quantity,
            TRY_CONVERT(DECIMAL(18,2), NULLIF(LTRIM(RTRIM(sls_price)), '')) AS sls_price
        FROM bronze.crm_sales_details
        WHERE NULLIF(LTRIM(RTRIM(sls_ord_num)), '') IS NOT NULL;

        -- ===== ERP customer extra =====
        TRUNCATE TABLE silver.erp_cust_az12;

        INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
        SELECT
            NULLIF(LTRIM(RTRIM(cid)), '') AS cid,
            TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(bdate)), '')) AS bdate,
            NULLIF(LTRIM(RTRIM(gen)), '') AS gen
        FROM bronze.erp_cust_az12;

        -- ===== ERP location =====
        TRUNCATE TABLE silver.erp_loc_a101;

        INSERT INTO silver.erp_loc_a101 (cid, cntry)
        SELECT
            NULLIF(LTRIM(RTRIM(cid)), '') AS cid,
            NULLIF(LTRIM(RTRIM(cntry)), '') AS cntry
        FROM bronze.erp_loc_a101;

        -- ===== ERP product categories =====
        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
        SELECT
            NULLIF(LTRIM(RTRIM(id)), '') AS id,
            NULLIF(LTRIM(RTRIM(cat)), '') AS cat,
            NULLIF(LTRIM(RTRIM(subcat)), '') AS subcat,
            NULLIF(LTRIM(RTRIM(maintenance)), '') AS maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @end_time = SYSDATETIME();
        UPDATE dbo.etl_run_log
        SET end_time = @end_time,
            status = N'SUCCESS',
            message = CONCAT(N'Silver load complete. Duration: ', DATEDIFF(SECOND, @start_time, @end_time), N' seconds.')
        WHERE etl_run_id = @run_id;
    END TRY
    BEGIN CATCH
        SET @end_time = SYSDATETIME();
        UPDATE dbo.etl_run_log
        SET end_time = @end_time,
            status = N'FAILED',
            message = CONCAT(N'Error ', ERROR_NUMBER(), N': ', ERROR_MESSAGE())
        WHERE etl_run_id = @run_id;
        THROW;
    END CATCH
END;
GO
