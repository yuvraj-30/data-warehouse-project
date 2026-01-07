# Fortis-Style SQL Data Warehouse Project

## Overview
This project demonstrates an end-to-end SQL data warehouse designed to support **operational reporting, master data accuracy, and business decision-making** in a fast-moving commercial environment such as Fortis.

The warehouse follows a **Bronze → Silver → Gold** architecture to ensure data reliability, auditability, and clear separation between raw data ingestion and business-ready reporting tables.

The primary business focus is on **customer and product master data**, ensuring consistent keys, clean attributes, and reliable relationships across systems.

---

## Power BI Dashboard Preview (Gold Layer)
The Gold layer produces stable, reporting-ready tables (e.g., `report_customers`, `report_products`) designed for consumption by Power BI.

![Customer Master Data Dashboard](powerbi/screenshots/dashboard_customer_360.png)

![Product Performance Dashboard](powerbi/screenshots/dashboard_product_performance.png)

![Data Quality Monitoring Dashboard](powerbi/screenshots/dashboard_data_quality.png)

> Note: Screenshots are included as recruiter-facing evidence of reporting design. The underlying data comes from the Gold reporting outputs.

---

## Business Problem
Operational businesses rely on accurate customer and product data to:
- Maintain reliable ERP master data
- Produce consistent reports
- Reduce reconciliation issues across systems
- Enable confident decision-making

Source systems often contain:
- Duplicate customers or products
- Inconsistent naming or identifiers
- Missing or late-arriving records

This warehouse addresses those issues by standardising, validating, and governing customer and product data before it is consumed by reporting and analytics.

---

## Architecture

### Bronze Layer (Raw Ingestion)
- Stores source data **as received** from upstream systems
- No transformations beyond basic type handling
- Append-only with load timestamps for auditability

### Silver Layer (Cleansed & Conformed)
- Cleans and standardises raw data
- Applies business rules and validations
- Resolves duplicates and normalises formats
- Prepares data for dimensional modelling

### Gold Layer (Business-Ready Tables)
- Star-schema design with fact and dimension tables
- Optimised for reporting and analytics
- Stable schemas for downstream consumption (Power BI / Python)

---

## Dimensional Model

### Core Dimensions
- **dim_customer**: Master list of customers with surrogate keys
- **dim_product**: Master list of products with standardised attributes

Surrogate keys are used to:
- Ensure consistency across systems
- Isolate reporting from source system key changes
- Support historical tracking

### Fact Tables
- Store transactional or measurable business events
- Reference customer and product dimensions via surrogate keys

---

## Customer & Product Mapping

Customer and product mapping is a core feature of this warehouse:
- Source system identifiers are mapped to **single master records**
- Duplicate records are resolved using deterministic rules
- Missing or invalid foreign keys are detected through data quality checks
- Late-arriving dimension records are handled via controlled inserts

This approach ensures:
- Accurate ERP master data
- Consistent reporting across departments
- Reduced downstream reconciliation effort

---

## Data Quality & Governance

Built-in data quality controls include:
- Primary key uniqueness checks
- Foreign key integrity validation
- Mandatory field completeness checks
- Append-only logic with load timestamps

Violations are surfaced explicitly to support investigation and remediation rather than being silently ignored.

---

## Gold Tables & Business Use

Each Gold table is designed for direct business consumption:
- **Purpose**: Operational and management reporting
- **Consumers**: Analysts, reporting tools, dashboards (Power BI)
- **Refresh Pattern**: Incremental append with timestamps
- **Typical Questions Answered**:
  - How many active customers and products do we have?
  - Are there data quality issues impacting reporting?
  - How do customers and products relate across transactions?

---

## Tools & Technologies
- SQL Server–compatible SQL
- Relational modelling (Star Schema)
- Data quality enforcement via SQL

---

## How This Aligns With the Fortis Data Analyst Role
This project directly demonstrates the ability to:
- Gather and organise data from multiple systems
- Clean and prepare data for accuracy and reliability
- Maintain customer and product master data
- Support operational reporting and analysis
- Follow data quality best practices

---

## Next Steps
This warehouse is designed to be consumed by analytics and reporting tools (e.g. Python, Power BI) via the Gold layer, enabling end-to-end data-driven decision support.


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


## Solution Architecture & Data Governance

This project is designed to support operational customer and product reporting in a wholesale environment.

- **End-to-End Data Warehouse Architecture**  
  Visual overview of how customer and product data flows from source systems into reporting-ready datasets.  
  `docs/reference/fortis_data_architecture.png`

- **Customer, Product & Sales Relationships**  
  Business view of the core entities supporting operational analytics.  
  `docs/reference/fortis_customer_product_sales.png`

- **Data Quality & Governance Summary**  
  Summary of automated validation checks executed upstream in SQL and Python.  
  `docs/reference/fortis_data_quality_summary.pdf`
