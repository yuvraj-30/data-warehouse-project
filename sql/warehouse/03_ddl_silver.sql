/*
===============================================================================
03_ddl_silver
===============================================================================
Technical Objective: Define Silver layer tables to support cleansing, standardisation, and cross-system conformance.
===============================================================================
*/

/*
Purpose:
  Create SILVER (cleaned, standardized) tables.

Design:
  - Silver tables hold cleansed data with appropriate datatypes.
  - This script is idempotent: it creates tables only if they do not exist.
*/
USE DataWarehouse;
GO 

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver') EXEC('CREATE SCHEMA silver');
GO

-- CRM customers
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NULL
BEGIN
    CREATE TABLE silver.crm_cust_info (
        cst_id            INT           NOT NULL,
        cst_key           NVARCHAR(50)  NOT NULL,
        cst_firstname     NVARCHAR(200) NULL,
        cst_lastname      NVARCHAR(200) NULL,
        cst_marital_status NVARCHAR(50) NULL,
        cst_gender        NVARCHAR(50)  NULL,
        cst_create_date   DATE          NULL,
        CONSTRAINT PK_silver_crm_cust_info PRIMARY KEY (cst_id)
    );
END;
GO

-- CRM products (type-2 like history using start/end date)
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NULL
BEGIN
    CREATE TABLE silver.crm_prd_info (
        prd_id        INT            NOT NULL,
        cat_id        NVARCHAR(50)   NULL,
        prd_key       NVARCHAR(50)   NOT NULL,
        prd_nm        NVARCHAR(400)  NULL,
        prd_cost      DECIMAL(18,2)  NOT NULL DEFAULT (0),
        prd_line      NVARCHAR(50)   NULL,
        prd_start_dt  DATE           NULL,
        prd_end_dt    DATE           NULL,
        CONSTRAINT PK_silver_crm_prd_info PRIMARY KEY (prd_id, prd_key)
    );
END;
GO

-- CRM sales details
IF OBJECT_ID('silver.crm_sales_details', 'U') IS NULL
BEGIN
    CREATE TABLE silver.crm_sales_details (
        sls_ord_num   NVARCHAR(50)  NOT NULL,
        sls_prd_key   NVARCHAR(50)  NOT NULL,
        sls_cust_id   INT           NOT NULL,
        sls_order_dt  DATE          NULL,
        sls_ship_dt   DATE          NULL,
        sls_due_dt    DATE          NULL,
        sls_sales     DECIMAL(18,2) NULL,
        sls_quantity  INT           NULL,
        sls_price     DECIMAL(18,2) NULL
    );
    CREATE INDEX IX_silver_sales_cust ON silver.crm_sales_details (sls_cust_id);
    CREATE INDEX IX_silver_sales_prd  ON silver.crm_sales_details (sls_prd_key);
END;
GO

-- ERP customer extra info
IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NULL
BEGIN
    CREATE TABLE silver.erp_cust_az12 (
        cid     NVARCHAR(50) NULL,
        bdate   DATE         NULL,
        gen     NVARCHAR(50) NULL
    );
END;
GO

-- ERP customer location
IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NULL
BEGIN
    CREATE TABLE silver.erp_loc_a101 (
        cid     NVARCHAR(50)  NULL,
        cntry   NVARCHAR(100) NULL
    );
END;
GO

-- ERP product categories
IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NULL
BEGIN
    CREATE TABLE silver.erp_px_cat_g1v2 (
        id          NVARCHAR(50)  NULL,
        cat         NVARCHAR(200) NULL,
        subcat      NVARCHAR(200) NULL,
        maintenance NVARCHAR(50)  NULL
    );
END;
GO
