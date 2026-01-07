# Run Order (SQL Server)

This project is designed for **Microsoft SQL Server** and is easiest to run in **SQL Server Management Studio (SSMS)**.

## Option 1 (Recommended): Run everything with SQLCMD Mode
1. Open `run/run_all.sql` in SSMS
2. Enable **SQLCMD Mode** (Query → SQLCMD Mode)
3. Execute the script

## Option 2: Manual run (file-by-file)
Run the scripts below in order (all are T-SQL / SQL Server compatible).

### 0) Initialize database + schemas
- `sql/warehouse/00_init_database.sql`

### 1) Bronze layer (raw ingestion)
- `sql/warehouse/01_ddl_bronze.sql`
- `sql/warehouse/02_proc_load_bronze.sql`

### 2) Silver layer (clean + standardized)
- `sql/warehouse/03_ddl_silver.sql`
- `sql/warehouse/04_proc_load_silver.sql`
- `sql/warehouse/06_quality_checks_silver.sql` *(report-only)*

### 3) Gold layer (star schema tables)
- `sql/warehouse/05_ddl_gold.sql`
- `sql/warehouse/05_proc_load_gold.sql`
- `sql/warehouse/07_quality_checks_gold.sql` *(report-only)*

### 4) Analytics & reporting marts
- `sql/analytics/00_init_database.sql`
- `sql/analytics/01_database_exploration.sql` through `sql/analytics/11_part_to_whole_analysis.sql`
- Reporting marts:
  - `sql/analytics/12_report_customers.sql`
  - `sql/analytics/13_report_products.sql`

### 5) Append-only DQ reporting (recommended for portfolios)
- `sql/warehouse/08_dq_report_gold.sql` *(report-only; appends run results with timestamps)*

## Outputs
- Gold layer CSV extracts: `data/gold/`
- Business-ready report extracts: `reports/`
