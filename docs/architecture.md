# Architecture

This repository demonstrates an end-to-end analytics implementation, from raw source extracts (CRM + ERP) through a layered data warehouse (Bronze → Silver → Gold) and into analytics/reporting marts.

## Layers

### Source (Raw)
- **Purpose:** Preserve original CRM/ERP extracts unchanged for traceability.
- **Location:** `data/source/`
- **Typical content:** operational tables exported from source applications.

### Bronze (Landing)
- **Purpose:** Ingest source data into the warehouse with minimal transformation (type coercion, basic standardisation).
- **Location:** `data/bronze/` (CSV extracts) and `sql/warehouse/01_ddl_bronze.sql`, `sql/warehouse/02_proc_load_bronze.sql`
- **Notes:** Bronze is expected to contain duplicates, nulls, inconsistent formatting—reflecting real operational systems.

### Silver (Cleansed + Conformed)
- **Purpose:** Cleanse, validate, and conform data for integration across systems.
- **Location:** `data/silver/` and `sql/warehouse/03_ddl_silver.sql`, `sql/warehouse/04_proc_load_silver.sql`
- **Typical work:** de-duplication, standardised keys, data type alignment, referential rules, and mapping.

### Gold (Analytics Model)
- **Purpose:** Publish analytics-ready tables: star schema (dimensions + fact) and reporting marts.
- **Location:** `data/gold/` and `sql/warehouse/05_ddl_gold.sql`
- **Output:** `gold.dim_customers`, `gold.dim_products`, `gold.fact_sales`, plus report marts.

## Analytics & Reporting
- **Purpose:** Answer business questions (ranking, trends, segmentation, performance) and produce business-facing tables.
- **Location:** `sql/analytics/` and outputs in `reports/`

## How to Use This Document
- For run steps, see `run/run_order.md`.
- For customer/product mapping rules, see `docs/mapping_rules.md`.
- For field-level definitions, see `docs/data_dictionary.md`.
