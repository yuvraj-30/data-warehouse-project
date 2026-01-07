/*
===============================================================================
02_proc_load_bronze
===============================================================================
Technical Objective: Load CRM/ERP source extracts into Bronze tables and record ETL run status.
===============================================================================
*/

/*
Purpose:
  Load raw CSV files into BRONZE tables using BULK INSERT.

Assumptions:
  - Files are located in a folder path accessible to SQL Server.
  - Filenames are:
      crm_cust_info.csv
      crm_prd_info.csv
      crm_sales_details.csv
      erp_cust_az12.csv
      erp_loc_a101.csv
      erp_px_cat_g1v2.csv

Usage:
  EXEC bronze.proc_load_bronze @bronze_folder_path = N'C:\data\';
*/

CREATE OR ALTER PROCEDURE bronze.proc_load_bronze
    @bronze_folder_path NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @run_id INT;
    INSERT INTO dbo.etl_run_log(layer_name, procedure_name)
    VALUES (N'bronze', N'bronze.proc_load_bronze');
    SET @run_id = SCOPE_IDENTITY();

    DECLARE
        @start_time DATETIME2(0) = SYSDATETIME(),
        @end_time   DATETIME2(0),
        @sql        NVARCHAR(MAX);

    BEGIN TRY
        -- Always truncate before full reloads
        TRUNCATE TABLE bronze.crm_cust_info;
        TRUNCATE TABLE bronze.crm_prd_info;
        TRUNCATE TABLE bronze.crm_sales_details;
        TRUNCATE TABLE bronze.erp_cust_az12;
        TRUNCATE TABLE bronze.erp_loc_a101;
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        -- Helper macro: BULK INSERT with UTF-8, header row skipped
        -- Note: we use dynamic SQL to avoid quoting pitfalls.
        DECLARE @bulk_template NVARCHAR(MAX) = N'
BULK INSERT {table}
FROM ''{file}''
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''0x0a'',
    TABLOCK,
    CODEPAGE = ''65001'',
    KEEPNULLS
);';

        DECLARE @p NVARCHAR(4000) = @bronze_folder_path;
        IF RIGHT(@p, 1) NOT IN ('\', '/')
            SET @p = @p + N'\';

        -- crm_cust_info
        SET @sql = REPLACE(REPLACE(@bulk_template, N'{table}', N'bronze.crm_cust_info'), N'{file}', @p + N'crm_cust_info.csv');
        EXEC sys.sp_executesql @sql;

        -- crm_prd_info
        SET @sql = REPLACE(REPLACE(@bulk_template, N'{table}', N'bronze.crm_prd_info'), N'{file}', @p + N'crm_prd_info.csv');
        EXEC sys.sp_executesql @sql;

        -- crm_sales_details
        SET @sql = REPLACE(REPLACE(@bulk_template, N'{table}', N'bronze.crm_sales_details'), N'{file}', @p + N'crm_sales_details.csv');
        EXEC sys.sp_executesql @sql;

        -- erp_cust_az12
        SET @sql = REPLACE(REPLACE(@bulk_template, N'{table}', N'bronze.erp_cust_az12'), N'{file}', @p + N'erp_cust_az12.csv');
        EXEC sys.sp_executesql @sql;

        -- erp_loc_a101
        SET @sql = REPLACE(REPLACE(@bulk_template, N'{table}', N'bronze.erp_loc_a101'), N'{file}', @p + N'erp_loc_a101.csv');
        EXEC sys.sp_executesql @sql;

        -- erp_px_cat_g1v2
        SET @sql = REPLACE(REPLACE(@bulk_template, N'{table}', N'bronze.erp_px_cat_g1v2'), N'{file}', @p + N'erp_px_cat_g1v2.csv');
        EXEC sys.sp_executesql @sql;

        SET @end_time = SYSDATETIME();

        UPDATE dbo.etl_run_log
        SET end_time = @end_time,
            status = N'SUCCESS',
            message = CONCAT(N'Bronze load complete. Duration: ', DATEDIFF(SECOND, @start_time, @end_time), N' seconds.')
        WHERE etl_run_id = @run_id;
    END TRY
    BEGIN CATCH
        SET @end_time = SYSDATETIME();
        UPDATE dbo.etl_run_log
        SET end_time = @end_time,
            status = N'FAILED',
            message = CONCAT(N'Error ', ERROR_NUMBER(), N': ', ERROR_MESSAGE())
        WHERE etl_run_id = @run_id;

        -- rethrow for visibility in CI / manual runs
        THROW;
    END CATCH
END;
GO
