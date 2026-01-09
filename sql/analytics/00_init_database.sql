/*
===============================================================================
00_init_database (INTEGRATED ANALYTICS)
===============================================================================
Purpose:
  Create a dedicated analytics database that CONSUMES the warehouse Gold layer.

Design:
  - SAFE for reviewers: does NOT drop databases.
  - Analytics uses views over DataWarehouse.gold.* (single source of truth).
  - A separate schema (analytics_gold) is used to avoid confusion with DataWarehouse.gold.

Assumptions:
  - Warehouse database: DataWarehouse
  - Warehouse Gold schema: gold
===============================================================================
*/

USE master;
GO

IF DB_ID(N'DataWarehouseAnalytics') IS NULL
BEGIN
    CREATE DATABASE DataWarehouseAnalytics;
END;
GO

USE DataWarehouseAnalytics;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'analytics_gold')
    EXEC(N'CREATE SCHEMA analytics_gold');
GO

-- Validate warehouse prerequisites (fail fast with clear message)
IF DB_ID(N'DataWarehouse') IS NULL
    THROW 50001, 'Warehouse database [DataWarehouse] not found. Run the warehouse build first.', 1;

IF OBJECT_ID(N'DataWarehouse.gold.dim_customers', 'U') IS NULL
    THROW 50002, 'Missing object [DataWarehouse].[gold].[dim_customers]. Run Gold load first.', 1;

IF OBJECT_ID(N'DataWarehouse.gold.dim_products', 'U') IS NULL
    THROW 50003, 'Missing object [DataWarehouse].[gold].[dim_products]. Run Gold load first.', 1;

IF OBJECT_ID(N'DataWarehouse.gold.fact_sales', 'U') IS NULL
    THROW 50004, 'Missing object [DataWarehouse].[gold].[fact_sales]. Run Gold load first.', 1;
GO

-- Views (always reflect latest warehouse Gold)
CREATE OR ALTER VIEW analytics_gold.vw_dim_customers AS
SELECT * FROM DataWarehouse.gold.dim_customers;
GO

CREATE OR ALTER VIEW analytics_gold.vw_dim_products AS
SELECT * FROM DataWarehouse.gold.dim_products;
GO

CREATE OR ALTER VIEW analytics_gold.vw_fact_sales AS
SELECT * FROM DataWarehouse.gold.fact_sales;
GO
