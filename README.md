# Fortis-Style SQL Data Warehouse & Analytics Project

## Overview

This project implements an **end-to-end data warehouse** using a **Bronze → Silver → Gold** architecture to transform raw CRM and ERP data into **business-ready datasets** for reporting and analytics.

Key focus areas:
- Customer and product mapping across systems  
- Data quality and governance before reporting  
- Reporting-ready models optimised for BI tools  

The solution reflects how data is handled in a **commercial wholesale environment**.

---

## High-Level Architecture

The following diagram shows the **overall system architecture**, from source systems through to reporting consumption.  
It provides a visual summary of how data flows through the Bronze, Silver, and Gold layers.

![High Level Architecture](docs/reference/data_architecture.png)

**Architecture explanation:**
- **Sources**: CRM and ERP data provided as CSV files  
- **Bronze layer**: Raw ingestion with no transformations  
- **Silver layer**: Cleansed and standardised data with business rules applied  
- **Gold layer**: Business-ready dimensional models and reporting views  
- **Consumption**: Power BI dashboards, ad-hoc SQL queries, and analytics  

This layered design ensures **traceability, data quality, and reporting confidence**.

---

## Data Flow & Lineage

The diagram below illustrates **data lineage**, showing how individual source tables move through each warehouse layer.

![Data Flow](docs/reference/data_flow.png)

**Key points:**
- CRM and ERP datasets are ingested independently  
- Each dataset is validated and standardised in the Silver layer  
- Only validated data is promoted to the Gold layer  
- Clear lineage simplifies debugging and data quality assurance  

---

## Customer & Product Integration

Accurate customer and product mapping is critical for operational reporting.

![Data Integration](docs/reference/data_integration.png)

**Integration approach:**
- CRM provides transactional sales data and identifiers  
- ERP enriches customer and product attributes  
- Mapping rules resolve mismatches and ensure a single trusted view  

Detailed logic is documented in:
- [`docs/reference/mapping_rules.md`](docs/reference/mapping_rules.md)

---

## Data Quality & Governance

Data quality checks are executed **before data reaches the reporting layer**.

Implemented validations include:
- negative quantity and sales checks  
- invalid or zero pricing checks  
- missing customer and product key detection  
- referential integrity validation  

SQL implementations:
- Silver layer checks: `06_quality_checks_silver.sql`  
- Gold layer checks: `07_quality_checks_gold.sql`  

Only validated data is exposed for reporting, ensuring **trustworthy insights**.

---

## Sales Data Mart (Gold Layer)

The Gold layer is designed using **dimensional modelling principles** to support analytics and BI tools.

📎 Detailed schema:
- [`docs/reference/data_model.png`](docs/reference/data_model.png)

**Characteristics:**
- star-schema-style design  
- customer and product dimensions  
- central sales fact table  
- pre-calculated business measures  

This structure supports efficient Power BI reporting and SQL analysis.

---

## Reporting & Analytics

Gold-layer datasets are consumed via:
- **Power BI dashboards** for operational reporting  
- **Ad-hoc SQL queries** for analysis and validation  

Dashboards focus on:
- customer overview and segmentation  
- product performance  
- sales and order behaviour  
- data quality transparency  

Power BI assets are included under the `powerbi/` directory.

---

## Power BI Reporting (Gold Layer Consumption)

The Gold-layer datasets are consumed through **Power BI dashboards** designed for
operational reporting and day-to-day business analysis. These dashboards demonstrate
how cleansed, governed data is ultimately delivered to business users.

### Customer Master Dashboard
![Customer Master Dashboard](powerbi/screenshots/dashboard_customer_360.png)

### Product Performance Dashboard
![Product Performance Dashboard](powerbi/screenshots/dashboard_product_performance.png)

### Data Quality Monitoring
![Data Quality Dashboard](powerbi/screenshots/dashboard_data_quality.png)

---

## Supporting Documentation

Additional reference materials:
- Naming standards: [`docs/reference/naming_conventions.md`](docs/reference/naming_conventions.md)  
- Mapping rules: [`docs/reference/mapping_rules.md`](docs/mapping_rules.md)  
- ETL concepts (reference): [`docs/reference/ETL.png`](docs/reference/ETL.png)

These provide depth without cluttering the main narrative.

---

*Prepared as part of a targeted application for Fortis (Timaru, Canterbury).* 
