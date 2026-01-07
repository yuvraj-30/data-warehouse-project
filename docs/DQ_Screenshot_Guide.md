# Data Quality Screenshot Guide (Gold Layer)

This guide helps you capture **clean, recruiter-friendly screenshots** that prove:
- you validate data (not just transform it),
- you quantify issues,
- the pipeline completes end-to-end without blocking.

These screenshots are especially relevant to roles involving **customer/product mapping** and **ERP-style master data accuracy**.

---

## Before you start

1. Run the full pipeline:
   - Open `run/run_all.sql`
   - Enable **SQLCMD Mode** in SSMS
   - Execute

2. Confirm DQ tables exist (Gold schema):
   - `gold.dq_summary`
   - `gold.dq_sales_checks`
   - `gold.dq_customer_checks`
   - `gold.dq_product_checks`
   - `gold.dq_mapping_checks`

> All DQ checks are **report-only**: they never stop the run, and each execution appends a new record with a `run_id` and `run_ts`.

---

## Screenshot 1 — “DQ Summary (Latest Run)” (most important)

Run:

```sql
SELECT TOP (1) *
FROM gold.dq_summary
ORDER BY run_ts DESC;
```

**Screenshot goal:** show a single-row summary with `rows_checked`, `rows_flagged`, `% flagged`, and overall status per area.

---

## Screenshot 2 — “Sales Data Sanity Checks”

Run:

```sql
SELECT TOP (25)
  run_ts,
  check_name,
  rows_checked,
  rows_flagged,
  percent_flagged,
  severity
FROM gold.dq_sales_checks
ORDER BY run_ts DESC, rows_flagged DESC;
```

**Screenshot goal:** demonstrate business-critical checks like negative values, date ordering issues, and sales amount variance.

---

## Screenshot 3 — “Customer Master Data Checks”

Run:

```sql
SELECT TOP (25)
  run_ts,
  check_name,
  rows_checked,
  rows_flagged,
  percent_flagged,
  severity
FROM gold.dq_customer_checks
ORDER BY run_ts DESC, rows_flagged DESC;
```

**Screenshot goal:** show customer master integrity (duplicates, missing enrichment, orphan customers).

---

## Screenshot 4 — “Product Master Data Checks”

Run:

```sql
SELECT TOP (25)
  run_ts,
  check_name,
  rows_checked,
  rows_flagged,
  percent_flagged,
  severity
FROM gold.dq_product_checks
ORDER BY run_ts DESC, rows_flagged DESC;
```

**Screenshot goal:** show product master integrity (duplicate product keys, missing category enrichment, products never sold).

---

## Screenshot 5 — “Customer/Product Mapping Coverage (Rejects)”

Run:

```sql
SELECT TOP (25)
  run_ts,
  check_name,
  rows_checked,
  rows_flagged,
  percent_flagged,
  severity
FROM gold.dq_mapping_checks
ORDER BY run_ts DESC, rows_flagged DESC;
```

Optional (shows actual rejects table):

```sql
SELECT TOP (50) *
FROM gold.fact_sales_rejects
ORDER BY load_ts DESC;
```

**Screenshot goal:** prove you measure mapping quality—exactly what businesses care about when reconciling systems.

---

## Recommended screenshot order in your README

Use this order if you include screenshots:

1. DQ Summary (Latest Run)
2. Mapping Coverage (Rejects)
3. Sales Sanity Checks
4. Customer Master Checks
5. Product Master Checks

This tells the strongest story for operational roles.

---

## How to explain in an interview (30–45 seconds)

> “I run report-only data quality checks after the Gold load. The pipeline always completes, but I append a timestamped DQ summary and detailed checks so stakeholders can see exactly what needs attention—especially customer and product mapping coverage. This mirrors real ERP environments where data accuracy must be visible and measurable without blocking operations.”

---

## Tips for cleaner screenshots

- Sort by `run_ts DESC` so the latest run is visible.
- Expand SSMS results grid height to show 10–25 rows clearly.
- Highlight the `rows_flagged` and `percent_flagged` columns if your interviewer asks about impact.
