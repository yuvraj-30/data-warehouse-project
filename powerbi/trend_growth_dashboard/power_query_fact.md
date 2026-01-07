## Intended Audience
This document is intended for technical reviewers and internal reference.

# Power Query Steps (fact_sales)

1. Load gold.fact_sales.csv
2. Set data types:
   - order_date → Date
   - quantity → Whole Number
   - sales_amount → Fixed Decimal
3. Create Date table in Power BI:
   Date =
   ADDCOLUMNS(
     CALENDAR (DATE(2000,1,1), DATE(2030,12,31)),
     "Year", YEAR([Date]),
     "Month", FORMAT([Date], "MMM"),
     "MonthNumber", MONTH([Date]),
     "YearMonth", FORMAT([Date], "YYYY-MM")
   )
4. Mark Date table as date table
5. Relate Date[Date] → fact_sales[order_date]
