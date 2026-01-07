## Intended Audience
This document is intended for technical reviewers and internal reference.

# SQL Server note (optional)

If you prefer to use SQL Server as the data source (instead of importing CSVs):

1. Build the warehouse in SQL Server using `run/run_all.sql` (SQLCMD Mode in SSMS).
2. In Power BI Desktop, use **Get Data → SQL Server** and connect to the database.
3. Import:
   - `gold.fact_sales` for trends
   - (optional) `gold.dim_customers`, `gold.dim_products` for slicing
4. Use the DAX measures included in this folder.
