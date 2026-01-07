# Data Dictionary (High-Level)

This is a portfolio-friendly dictionary focusing on the Gold layer. For detailed/legacy notes, see `docs/reference/data_catalog.md`.

## Gold Tables

### `gold.dim_customers` (Customer Master)
**Grain:** 1 row per customer (conformed across CRM + ERP)

### `gold.dim_products` (Product Master)
**Grain:** 1 row per product/SKU (conformed across CRM + ERP)

### `gold.fact_sales` (Sales Fact)
**Grain:** 1 row per sales line (at the lowest available transactional level)

### `gold.report_customers`
**Purpose:** customer-level KPI table for reporting.

### `gold.report_products`
**Purpose:** product-level KPI table for reporting.
