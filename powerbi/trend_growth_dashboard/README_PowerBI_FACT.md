# Power BI Trend & Performance Report (fact_sales)

This report pack is designed to complement the aggregated report marts by using
`gold.fact_sales.csv` at transaction grain to enable **time-series analysis**.

## Purpose
- Monthly and yearly revenue trends
- Growth analysis (MoM / YoY)
- Category and customer contribution over time
- Performance monitoring

## Recommended Data Model
Single fact table with optional joins to:
- dim_customers
- dim_products

Primary date field: order_date (or equivalent)

## Pages

### Page 1 — Revenue Trends
KPIs:
- Total Revenue
- Total Orders
- Total Quantity
- Avg Order Value

Visuals:
- Line: Monthly Revenue
- Line: Monthly Orders
- Column: Revenue by Category (monthly)
- Line: Revenue vs Orders (dual axis)

### Page 2 — Growth Analysis
KPIs:
- MoM Growth %
- YoY Growth %

Visuals:
- Line: Monthly Revenue with MoM %
- Table: Revenue by Month with Growth
- Waterfall: Month-over-Month change

### Page 3 — Category Performance
Visuals:
- Stacked Column: Revenue by Category over Time
- Line: Avg Order Value by Category
- Matrix: Category x Month (Revenue)

### Page 4 — Customer Contribution
Visuals:
- Pareto: Cumulative Revenue by Customers
- Line: Active Customers by Month
- Column: New vs Returning Customers (optional)

## Interview Tip
Use this report to explain how you move from:
raw transactions → trends → business insight.
