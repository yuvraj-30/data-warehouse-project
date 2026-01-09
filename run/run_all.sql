PRINT 'Starting end-to-end warehouse build...';

-- =========================
-- 0) Create database objects
-- =========================
:r "C:\DW\SQL_Warehouse_Project_Fortis_Aligned\sql\warehouse\00_init_database.sql"
:r "C:\DW\SQL_Warehouse_Project_Fortis_Aligned\sql\warehouse\01_ddl_bronze.sql"
:r "C:\DW\SQL_Warehouse_Project_Fortis_Aligned\sql\warehouse\02_proc_load_bronze.sql"
:r "C:\DW\SQL_Warehouse_Project_Fortis_Aligned\sql\warehouse\03_ddl_silver.sql"
:r "C:\DW\SQL_Warehouse_Project_Fortis_Aligned\sql\warehouse\04_proc_load_silver.sql"
:r "C:\DW\SQL_Warehouse_Project_Fortis_Aligned\sql\warehouse\05_ddl_gold.sql"
:r "C:\DW\SQL_Warehouse_Project_Fortis_Aligned\sql\warehouse\05_proc_load_gold.sql"
:r "C:\DW\SQL_Warehouse_Project_Fortis_Aligned\sql\warehouse\06_quality_checks_silver.sql"
:r "C:\DW\SQL_Warehouse_Project_Fortis_Aligned\sql\warehouse\07_quality_checks_gold.sql"
:r "C:\DW\SQL_Warehouse_Project_Fortis_Aligned\sql\warehouse\08_dq_report_gold.sql"

-- =========================
-- 1) Execute the pipeline
-- =========================
PRINT 'Running pipeline procedures...';

-- Ensure we are in the correct database (consistent execution context)
USE DataWarehouse;
GO

-- 1A) Load Bronze (CSV ingestion)
EXEC bronze.proc_load_bronze
    @bronze_folder_path = N'C:\DW\SQL_Warehouse_Project_Fortis_Aligned\data\bronze\';

-- 1B) Load Silver (clean + standardize)
EXEC silver.proc_load_silver;

-- 1C) Load Gold (dims + fact + rejects)
EXEC gold.proc_load_gold;

-- 1D) Run DQ report (append-only)
:r "C:\DW\SQL_Warehouse_Project_Fortis_Aligned\sql\warehouse\08_dq_report_gold.sql"

-- =========================
-- 2) Quick validation output
-- =========================
PRINT 'Row counts (quick validation):';

SELECT 'bronze.crm_sales_details' AS table_name, COUNT(*) AS rows FROM bronze.crm_sales_details
UNION ALL SELECT 'silver.crm_sales_details', COUNT(*) FROM silver.crm_sales_details
UNION ALL SELECT 'gold.fact_sales', COUNT(*) FROM gold.fact_sales
UNION ALL SELECT 'gold.fact_sales_rejects', COUNT(*) FROM gold.fact_sales_rejects;

PRINT 'All done.';
