:setvar RootDir ".."
:setvar SqlDir "$(RootDir)\sql"

-- ============================================================
-- SQL Server end-to-end run (SQLCMD Mode)
-- Instructions:
-- 1) Open this file in SSMS
-- 2) Enable SQLCMD Mode: Query > SQLCMD Mode
-- 3) Set the $(RootDir) variable if your folder structure differs
-- 4) Execute
-- ============================================================

PRINT 'Starting end-to-end warehouse build...';

-- 0) Init database + schemas
:r "$(SqlDir)\warehouse\00_init_database.sql"

-- 1) Bronze (raw)
:r "$(SqlDir)\warehouse\01_ddl_bronze.sql"
:r "$(SqlDir)\warehouse\02_proc_load_bronze.sql"

-- 2) Silver (clean + standardized)
:r "$(SqlDir)\warehouse\03_ddl_silver.sql"
:r "$(SqlDir)\warehouse\04_proc_load_silver.sql"
:r "$(SqlDir)\warehouse\06_quality_checks_silver.sql"

-- 3) Gold (star schema tables)
:r "$(SqlDir)\warehouse\05_ddl_gold.sql"
:r "$(SqlDir)\warehouse\05_proc_load_gold.sql"
:r "$(SqlDir)\warehouse\07_quality_checks_gold.sql"

-- 4) Analytics (exploration + report marts)
:r "$(SqlDir)\analytics\00_init_database.sql"
:r "$(SqlDir)\analytics\01_database_exploration.sql"
:r "$(SqlDir)\analytics\02_dimensions_exploration.sql"
:r "$(SqlDir)\analytics\03_date_range_exploration.sql"
:r "$(SqlDir)\analytics\04_measures_exploration.sql"
:r "$(SqlDir)\analytics\05_magnitude_analysis.sql"
:r "$(SqlDir)\analytics\06_ranking_analysis.sql"
:r "$(SqlDir)\analytics\07_change_over_time_analysis.sql"
:r "$(SqlDir)\analytics\08_cumulative_analysis.sql"
:r "$(SqlDir)\analytics\09_performance_analysis.sql"
:r "$(SqlDir)\analytics\10_data_segmentation.sql"
:r "$(SqlDir)\analytics\11_part_to_whole_analysis.sql"
:r "$(SqlDir)\analytics\12_report_customers.sql"
:r "$(SqlDir)\analytics\13_report_products.sql"

-- 5) Report-only data quality summary (append with timestamp)
:r "$(SqlDir)\warehouse\08_dq_report_gold.sql"

PRINT 'All done.';
