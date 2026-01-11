-- ============================================================
-- End-to-end SSMS runner (SQLCMD Mode): Warehouse + Integrated Analytics
-- ============================================================
-- How to run:
-- 1) Open this file in SSMS
-- 2) Enable SQLCMD Mode: Query > SQLCMD Mode
-- 3) Execute
--
-- Assumption (edit if needed):
--   Project root extracted to: C:\DW\SQL_Warehouse_Project
-- ============================================================

PRINT 'Starting end-to-end build (Warehouse + Integrated Analytics)...';

-- =========================
-- 0) WAREHOUSE: create objects
-- =========================
:r "C:\DW\SQL_Warehouse_Project\sql\warehouse\00_init_database.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\warehouse\01_ddl_bronze.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\warehouse\02_proc_load_bronze.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\warehouse\03_ddl_silver.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\warehouse\04_proc_load_silver.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\warehouse\05_ddl_gold.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\warehouse\05_proc_load_gold.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\warehouse\06_quality_checks_silver.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\warehouse\07_quality_checks_gold.sql"

-- =========================
-- 1) WAREHOUSE: execute pipeline
-- =========================
PRINT 'Running Warehouse pipeline procedures...';

USE DataWarehouse;
GO

-- 1A) Bronze load (CSV ingestion)
EXEC bronze.proc_load_bronze
    @bronze_folder_path = N'C:\DW\SQL_Warehouse_Project\data\bronze\';

-- 1B) Silver load (clean + standardize)
EXEC silver.proc_load_silver;

-- 1C) Gold load (dims + fact + rejects)
EXEC gold.proc_load_gold;

-- 1D) Gold DQ report (append-only, report-only)
:r "C:\DW\SQL_Warehouse_Project\sql\warehouse\08_dq_report_gold.sql"

-- Quick validation (row counts)
PRINT 'Warehouse row counts (quick validation):';

SELECT 'bronze.crm_sales_details' AS table_name, COUNT(*) AS rows FROM bronze.crm_sales_details
UNION ALL SELECT 'silver.crm_sales_details', COUNT(*) FROM silver.crm_sales_details
UNION ALL SELECT 'gold.fact_sales', COUNT(*) FROM gold.fact_sales
UNION ALL SELECT 'gold.fact_sales_rejects', COUNT(*) FROM gold.fact_sales_rejects;

-- =========================
-- 2) ANALYTICS: build & run (Integrated consumption of DataWarehouse.gold.*)
-- =========================
PRINT 'Starting Integrated Analytics (consuming DataWarehouse.gold.*)...';

:r "C:\DW\SQL_Warehouse_Project\sql\analytics\00_init_database.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\analytics\01_database_exploration.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\analytics\02_dimensions_exploration.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\analytics\03_date_range_exploration.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\analytics\04_measures_exploration.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\analytics\05_magnitude_analysis.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\analytics\06_ranking_analysis.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\analytics\07_change_over_time_analysis.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\analytics\08_cumulative_analysis.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\analytics\09_performance_analysis.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\analytics\10_data_segmentation.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\analytics\11_part_to_whole_analysis.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\analytics\12_report_customers.sql"
:r "C:\DW\SQL_Warehouse_Project\sql\analytics\13_report_products.sql"

-- Quick validation (analytics views)
USE DataWarehouseAnalytics;
GO

PRINT 'Analytics row counts (quick validation):';

SELECT 'analytics_gold.vw_fact_sales' AS object_name, COUNT(*) AS rows FROM analytics_gold.vw_fact_sales
UNION ALL SELECT 'analytics_gold.vw_dim_customers', COUNT(*) FROM analytics_gold.vw_dim_customers
UNION ALL SELECT 'analytics_gold.vw_dim_products', COUNT(*) FROM analytics_gold.vw_dim_products;

PRINT 'All done (Warehouse + Integrated Analytics).';
