USE DataWarehouseAnalytics;
GO


/*
===============================================================================
Dimensions Exploration
===============================================================================
Purpose:
    - To explore the structure of dimension tables.
	
SQL Functions Used:
    - DISTINCT
    - ORDER BY
===============================================================================

Business Question: Which customer and product attributes are available to support customer/product mapping across CRM and ERP systems?
*/

-- Retrieve a list of unique countries from which customers originate
SELECT DISTINCT 
    country 
FROM analytics_gold.vw_dim_customers
ORDER BY country;

-- Retrieve a list of unique categories, subcategories, and products
SELECT DISTINCT 
    category, 
    subcategory, 
    product_name 
FROM analytics_gold.vw_dim_products
ORDER BY category, subcategory, product_name;
