# Power BI Report Pack (Built from report_customers.csv & report_products.csv)

This pack gives you a ready-to-implement **Power BI report specification** (pages, visuals, measures, and Power Query steps)
using the project outputs:

- `gold.report_customers.csv` (rows: 18482, cols: 14)
- `gold.report_products.csv` (rows: 130, cols: 16)

> Note: These are **pre-aggregated** marts. They work well for ranking/segmentation dashboards, but they are **not ideal**
for time-series trending (no daily/monthly grain). For trends, connect Power BI to `gold.fact_sales.csv`.

---

## Recommended data model
Two independent tables (no relationships required):

- **Customers Report**: one row per customer
- **Products Report**: one row per product

Set data types:
- Dates: `last_order_date`, `last_sale_date`
- Whole numbers: `total_orders`, `total_quantity`, `total_customers`
- Currency/Decimal: `total_sales`, `avg_order_value`, `avg_selling_price`, `avg_order_revenue`, `avg_monthly_spend`, `avg_monthly_revenue`

---

## Pages (report layout)

### Page 1 — Executive Summary
**KPIs (Cards)**
- Total Sales (Customers)
- Total Orders (Customers)
- Total Quantity (Customers)
- Avg Order Value (Customers)
- Total Products (count of product_key)

**Visuals**
- Top 10 Customers by Total Sales (bar)
- Top 10 Products by Total Sales (bar)
- Customer Segment Share (donut)
- Product Segment Share (donut)

**Slicers**
- Customer Segment
- Age Group
- Category / Subcategory
- Recency buckets (calculated)

---

### Page 2 — Customer Insights
**KPIs**
- Total Customers
- VIP Customers
- Avg Monthly Spend
- Avg Recency (days)

**Visuals**
- Customer distribution by Age Group (bar)
- Total Sales by Customer Segment (bar)
- Recency distribution (histogram/binned bar)
- Scatter: Total Sales vs Total Orders (size = total_quantity)

---

### Page 3 — Product Insights
**KPIs**
- Total Products
- High-Performer Products
- Avg Selling Price
- Avg Monthly Revenue

**Visuals**
- Total Sales by Category/Subcategory (bar)
- Top Products by Avg Monthly Revenue (bar)
- Scatter: Total Sales vs Total Customers (size = total_quantity)
- Recency in Months distribution (binned bar)

---

### Page 4 — Mapping & Data Quality (Portfolio page)
**Goal:** show you understand master data governance.

**Visuals**
- Counts: #Customers with missing age, missing segment, missing last order date
- Outlier table: customers with unusually high AOV
- Outlier table: products with unusually high avg_selling_price

---

## Calculated columns (optional, recommended)

### Customers: Recency Bucket
Bucket `recency` into:
- 0–30
- 31–90
- 91–180
- 181–365
- 365+

### Products: Recency Bucket (Months)
Bucket `recency_in_months` into:
- 0–3
- 4–6
- 7–12
- 13–24
- 24+

---

## Implementation
1. Power BI Desktop → Get Data → Text/CSV → load both CSVs.
2. Apply Power Query steps (see `power_query_m.md`).
3. Add measures (see `dax_measures.txt`).
4. Build pages as per layout above.
