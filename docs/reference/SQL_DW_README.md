## Intended Audience
This document is intended for technical reviewers and internal reference.

# SQL Data Warehouse Project (Bronze → Silver → Gold)
*A portfolio-style SQL Server data warehouse implementing ingestion, transformation, and analytical modelling for CRM + ERP datasets.*

## Why this project exists
This project demonstrates an end-to-end **data warehouse build** on SQL Server using a practical **Bronze / Silver / Gold** pattern:

- **Bronze**: raw ingestion (as-is) from CRM/ERP CSV extracts  
- **Silver**: cleaned + standardized tables (data quality, typing, deduplication)  
- **Gold**: business-ready star schema (facts + dimensions) for reporting (e.g., Power BI)

It is designed to show skills that are directly relevant to commercial environments: **data cleaning, master data consistency, customer/product mapping concepts, repeatable SQL pipelines, and quality checks**.

---

## Architecture (high level)
**Sources → SQL Server → Data Warehouse (Bronze/Silver/Gold) → BI & Reporting**

Key concepts:
- Stored procedures orchestrate loads and transformations.
- Silver layer applies business rules and standardisation.
- Gold layer exposes **analytics-friendly objects** (facts & dimensions).

See diagrams in `docs/`:
- `docs/data_architecture.*`
- `docs/data_flow.*`
- `docs/data_model.*`

---

## Repository structure
```
data-warehouse-project/
├── datasets/                  # Raw CRM/ERP CSV extracts used for the project
├── docs/                      # Architecture + documentation (catalog, naming conventions, diagrams)
├── scripts/
│   ├── init_database.sql      # Database + schema setup
│   ├── ddl_bronze.sql         # Bronze layer tables (raw)
│   ├── proc_load_bronze.sql   # Load Bronze from CSVs (BULK INSERT)
│   ├── ddl_silver.sql         # Silver tables (clean + standardised)
│   ├── proc_load_silver.sql   # Transform Bronze → Silver
│   ├── ddl_gold.sql           # Gold views / star schema objects
│   └── tests/
│       ├── quality_checks_silver.sql
│       └── quality_checks_gold.sql
└── requirements.txt           # (optional) tooling notes (if any)
```

---

## Data sources
This project uses two source domains:

### CRM
- Customer information (`cust_info.csv`)
- Product information (`prd_info.csv`)
- Sales transactions (`sales_details.csv`)

### ERP
- Customer enrichment (`CUST_AZ12.csv`)
- Location enrichment (`LOC_A101.csv`)
- Product categories (`PX_CAT_G1V2.csv`)

A field-level catalogue is in `docs/data_catalog.md`.

---

## How to run (SQL Server)
### Prerequisites
- Microsoft SQL Server (Developer edition is fine)
- SQL Server Management Studio (SSMS) or Azure Data Studio
- Access to the CSV datasets under `datasets/`

### Step 0 — Put the CSVs on the SQL Server machine
The script `proc_load_bronze.sql` uses `BULK INSERT`, which requires that:
- SQL Server can **read the CSV files** from the path you specify.
- The file path in the script matches your environment.

Recommended approach:
1. Create a folder on the SQL Server host, e.g. `C:\DW\datasets\`
2. Copy the CSVs from this repo’s `datasets/` into that folder
3. Update the `BULK INSERT` paths in `scripts/proc_load_bronze.sql` accordingly

### Step 1 — Create database + schemas
Run:
1. `scripts/init_database.sql`

### Step 2 — Create Bronze tables
Run:
1. `scripts/ddl_bronze.sql`

### Step 3 — Load Bronze from CSVs
Run:
1. `scripts/proc_load_bronze.sql`

### Step 4 — Create Silver tables + transform
Run:
1. `scripts/ddl_silver.sql`
2. `scripts/proc_load_silver.sql`

### Step 5 — Create Gold layer (star schema objects)
Run:
1. `scripts/ddl_gold.sql`

### Step 6 — Run quality checks
Run:
- `tests/quality_checks_silver.sql`
- `tests/quality_checks_gold.sql`

---

## What to highlight in interviews
- **Repeatable pipeline**: scripts are separated by layer, and stored procedures provide clear orchestration.
- **Data quality mindset**: explicit quality checks in Silver/Gold.
- **Master data thinking**: customer/product enrichment from ERP complements CRM operational data.
- **Analytics-ready outputs**: Gold layer structured for BI use (facts + dimensions).

---

## Next improvements (planned)
- Parameterize file paths (or use SQL Server External Data Sources) instead of hard-coded paths
- Add load logging (row counts, timings, failure capture)
- Introduce incremental load strategy (watermarks) instead of full reloads
- Add indexes / constraints on keys used for joins in Gold
- Expand data tests (uniqueness, referential integrity, range checks)

---

## Author
Yuvraj Singh


## Dashboard Focus
Primary focus is on operational customer and product reporting. Trend and growth dashboards are supplementary.


## Architecture & Documentation

The solution design, data relationships, and governance approach are documented using professional draw.io diagrams and reference artefacts.

- 📐 **End-to-End Architecture**
  - `docs/reference/fortis_data_architecture.drawio`
  - `docs/reference/fortis_data_architecture.png`
  - `docs/reference/fortis_data_architecture.pdf`

- 🔗 **Customer–Product–Sales Relationships**
  - `docs/reference/fortis_customer_product_sales.drawio`
  - `docs/reference/fortis_customer_product_sales.png`
  - `docs/reference/fortis_customer_product_sales.pdf`

- 🛡 **Data Quality Summary**
  - `docs/reference/fortis_data_quality_summary.pdf`
