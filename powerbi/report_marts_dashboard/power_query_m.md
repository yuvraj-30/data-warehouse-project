## Intended Audience
This document is intended for technical reviewers and internal reference.

# Power Query (M) Steps (Recommended)

For each table after import:

1) Promote headers
2) Set correct data types:
   - Dates: last_order_date / last_sale_date
   - Whole number: keys, total_orders, total_quantity, total_customers, recency fields
   - Decimal number: averages
   - Fixed decimal / Currency: total_sales, avg_order_value, avg_monthly_spend, avg_monthly_revenue, avg_order_revenue, avg_selling_price
3) Trim customer_name/product_name (optional)
4) Replace blanks with nulls (optional)
5) Create recency buckets as calculated columns in DAX (recommended) or in Power Query

Tip: keep Power Query light; do modeling in DAX where possible for transparency in interviews.
