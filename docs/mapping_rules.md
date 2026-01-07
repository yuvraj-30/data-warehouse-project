# Customer & Product Mapping Rules (CRM ↔ ERP)

Wholesalers commonly run multiple systems (e.g., CRM for commercial activity, ERP for master data/pricing). This project focuses on producing **conformed Customer Master and Product Master** so reporting is consistent across systems.

## Customer Mapping

### Inputs
- CRM: `cust_info` (commercial/customer details)
- ERP: `CUST_AZ12` + `LOC_A101` (master and location attributes)

### Mapping approach (conceptual)
1. **Primary key alignment**: prefer stable business identifiers (customer code / account number) when present.
2. **Standardisation before matching**: trim whitespace, standardise casing, remove non-printing characters.
3. **De-duplication**: retain the “best” record using business rules (e.g., most complete attributes; most recent update when available).
4. **Location enrichment**: attach ERP location attributes when the location key is valid; otherwise flag as “Unknown/Unmapped”.

### Outputs
- `gold.dim_customers` (Customer Master)
- `gold.report_customers` (customer-facing report mart)

## Product Mapping

### Inputs
- CRM: `prd_info` (commercial product attributes)
- ERP: `PX_CAT_G1V2` (pricing/category reference)

### Mapping approach (conceptual)
1. **SKU / product code standardisation**: normalise product codes to a consistent format before joining.
2. **Category and pricing enrichment**: map ERP pricing categories onto the Product Master for consistent pricing analysis.
3. **De-duplication**: resolve SKU duplicates to a single canonical product record.

### Outputs
- `gold.dim_products` (Product Master)
- `gold.report_products` (product-facing report mart)

## Why this matters (business value)
- Prevents “same customer, different ID” problems across systems.
- Ensures product categories and pricing are consistently applied.
- Enables reliable reporting for top customers/products, trends, and performance.
