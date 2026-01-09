# Run Order (SQL Server – End-to-End)

This project is designed for **Microsoft SQL Server** and is intended to be executed in **SQL Server Management Studio (SSMS)**.

The pipeline follows a layered warehouse architecture (**Bronze → Silver → Gold**) with a separate **Integrated Analytics** database that consumes the Gold layer as a governed source of truth.

---

## Option 1 (Recommended): One-click end-to-end run (SQLCMD Mode)

This option builds **all objects** and **executes the full pipeline**, including analytics.

### Prerequisites
- SQL Server (local or developer edition)
- SQL Server Management Studio (SSMS)
- Project extracted to:
  ```
  C:\DW\SQL_Warehouse_Project_Fortis_Aligned
  ```

### Steps
1. Open `run/run_all.sql` in SSMS  
2. Enable **SQLCMD Mode** (Query → SQLCMD Mode)  
3. Execute the script (F5)

### What this does
- Creates warehouse schemas and tables
- Creates ETL stored procedures
- Executes:
  - Bronze CSV ingestion
  - Silver standardisation
  - Gold dimensional and fact loads
- Runs non-blocking data quality checks
- Builds the **Integrated Analytics** database
- Refreshes analytics report marts
- Prints validation row counts at the end

This is the **recommended approach for reviewers and recruiters**.

---

## Option 2: Manual execution (file-by-file)

Use this option if you want to understand or demonstrate each layer individually.

### 0) Initialize Warehouse database & schemas
```
sql/warehouse/00_init_database.sql
```

### 1) Bronze layer – raw ingestion
```
sql/warehouse/01_ddl_bronze.sql
sql/warehouse/02_proc_load_bronze.sql
```

Execute:
```sql
EXEC bronze.proc_load_bronze
    @bronze_folder_path = N'C:\DW\SQL_Warehouse_Project_Fortis_Aligned\data\bronze\';
```

### 2) Silver layer – cleaning & standardisation
```
sql/warehouse/03_ddl_silver.sql
sql/warehouse/04_proc_load_silver.sql
sql/warehouse/06_quality_checks_silver.sql
```

Execute:
```sql
EXEC silver.proc_load_silver;
```

### 3) Gold layer – dimensional model & facts
```
sql/warehouse/05_ddl_gold.sql
sql/warehouse/05_proc_load_gold.sql
sql/warehouse/07_quality_checks_gold.sql
```

Execute:
```sql
EXEC gold.proc_load_gold;
```

Append-only data quality reporting:
```
sql/warehouse/08_dq_report_gold.sql
```

### 4) Integrated Analytics (consumes Gold layer)
```
sql/analytics/00_init_database.sql
```

### 5) Analytics exploration & reporting
```
sql/analytics/01_database_exploration.sql
sql/analytics/02_dimensions_exploration.sql
sql/analytics/03_date_range_exploration.sql
sql/analytics/04_measures_exploration.sql
sql/analytics/05_magnitude_analysis.sql
sql/analytics/06_ranking_analysis.sql
sql/analytics/07_change_over_time_analysis.sql
sql/analytics/08_cumulative_analysis.sql
sql/analytics/09_performance_analysis.sql
sql/analytics/10_data_segmentation.sql
sql/analytics/11_part_to_whole_analysis.sql
sql/analytics/12_report_customers.sql
sql/analytics/13_report_products.sql
```

---

## Outputs & Validation

### Warehouse
- Star schema tables in `DataWarehouse.gold`
- Reject transparency via `gold.fact_sales_rejects`
- Append-only data quality history in `gold.dq_summary`

### Analytics
- Always-current views in `DataWarehouseAnalytics.analytics_gold`
- Report-ready marts/views in `DataWarehouseAnalytics.report`

---

## Notes for Reviewers
- The pipeline is **idempotent** and safe to re-run
- Analytics consume the warehouse Gold layer directly (no CSV reloads)
- Data quality checks are **non-blocking** and transparent
- The project mirrors a real ERP/CRM analytics workflow
