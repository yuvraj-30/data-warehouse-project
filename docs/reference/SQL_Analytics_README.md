## Intended Audience
This document is intended for technical reviewers and internal reference.

# Data Warehouse + Analytics Project (Bronze → Silver → Gold)

This repository contains an end-to-end analytics pipeline that ingests **CRM** and **ERP** data, applies **data quality and conformance rules**, and produces an **analytics-ready star schema** with customer/product reporting outputs.

It is designed to mirror a **commercial wholesale environment** where reporting requires **customer and product mapping across systems**—a common requirement in ERP contexts (master data management, pricing/category alignment, and reconciled reporting).

---

## Business Context

In wholesale/distribution settings (e.g., veterinary wholesalers), operational systems often split responsibilities:

- **CRM**: sales transactions, customer interactions, order lines
- **ERP**: customer master data, product master data, locations, pricing/category structures

A key challenge is ensuring **consistent customer and product identifiers** across systems so that downstream reporting (Power BI/Tableau/Excel) is accurate and trusted.

---

## Source Systems and Datasets

| Layer | Source | File | Purpose | Typical Grain |
|------:|--------|------|---------|---------------|
| Bronze | CRM | `bronze.crm_cust_info.csv` | Raw customer extract | Customer record |
| Bronze | CRM | `bronze.crm_prd_info.csv` | Raw product extract | Product record |
| Bronze | CRM | `bronze.crm_sales_details.csv` | Raw sales extract | Transaction / line-level |
| Bronze | ERP | `bronze.erp_cust_az12.csv` | Raw ERP customer master | Customer master |
| Bronze | ERP | `bronze.erp_loc_a101.csv` | Raw location reference | Location record |
| Bronze | ERP | `bronze.erp_px_cat_g1v2.csv` | Raw pricing/category mapping | Product category mapping |

Silver and Gold CSVs in this repo represent the **processed outputs** after cleansing/conformance and modeling.

---

## Customer and Product Mapping (CRM ↔ ERP)

This project explicitly addresses **customer & product mapping** to improve data accuracy across systems:

- **Customer mapping**: reconciles customer identifiers and attributes so reporting uses a single, conformed customer dimension.
- **Product mapping**: standardizes product identifiers, categories, and pricing/category relationships so product reporting is consistent.

Why it matters:
- Prevents duplicated customer/product entities in reports
- Enables reliable rollups by category/segment
- Improves trust in ERP master data used for operational decisions

---

## Target Model (Gold Layer)

### Star Schema

- `gold.fact_sales` — sales fact table used for all KPIs
- `gold.dim_customers` — customer master (conformed)
- `gold.dim_products` — product master (conformed)

### Table Grains

- **fact_sales grain:** 1 row per **customer × product × day** (transactional facts rolled to reporting grain)
- **dim_customers grain:** 1 row per **conformed customer**
- **dim_products grain:** 1 row per **conformed product**

### Reporting Outputs

- `gold.report_customers.csv` — customer performance view for account management
- `gold.report_products.csv` — product performance view for merchandising/inventory decisions

---

## How to Run (SQL Server / T-SQL)

1. **Initialize database**
   - Run: `00_init_database.sql`
   - Note: the script is destructive (drops and recreates DB). Use a dev environment.

2. **Explore / validate**
   - Run: `01_database_exploration.sql` → `04_measures_exploration.sql`

3. **Core analytics**
   - Run: `05_magnitude_analysis.sql` → `11_part_to_whole_analysis.sql`

4. **Generate reporting tables**
   - Run: `12_report_customers.sql`, `13_report_products.sql`

---

## Analytics Coverage

The SQL scripts cover a full set of business analyses:

- Ranking (top customers/products)
- Change-over-time (trend analysis)
- Cumulative performance (MTD/QTD/YTD patterns)
- Performance deltas (period-over-period improvements/declines)
- Segmentation (customer/product grouping)
- Part-to-whole (contribution and concentration)

Each script includes a **Business Question** at the top to keep analysis tied to real stakeholder needs.

---

## Data Quality and Best Practices

This project follows common best practices used in commercial analytics teams:

- Layered design (Bronze/Silver/Gold)
- Conformed dimensions for master data consistency
- Explicit joins and grouping logic for reproducible KPIs
- Comments and business-question framing for maintainability and handover

---

## Files Included

- SQL scripts: `00_*.sql` through `13_*.sql`
- CSV datasets for Bronze/Silver/Gold layers:
  - `bronze.*.csv`
  - `silver.*.csv`
  - `gold.*.csv`

---

## Notes for Reviewers / Recruiters

This project demonstrates practical skills aligned to entry-level Data Analyst roles in commercial environments:

- Multi-system data gathering (CRM + ERP)
- Data cleaning and preparation
- Customer/product mapping (master data)
- KPI reporting design that is Power BI/Tableau/Excel ready
- Commercial-style analysis: trends, ranking, segmentation, contribution



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
