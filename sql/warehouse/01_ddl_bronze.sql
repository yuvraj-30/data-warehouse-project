/*
===============================================================================
01_ddl_bronze
===============================================================================
Technical Objective: Define Bronze layer tables to land CRM/ERP extracts with minimal transformation for traceability.
===============================================================================
*/

/*
Purpose:
  Create BRONZE (raw) tables.

Design:
  - Bronze tables store raw ingested data with minimal constraints.
  - Use NVARCHAR for most columns to avoid load failures from dirty data.
  - Type casting and standardization happens in the SILVER layer.
*/
USE DataWarehouse;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bronze') EXEC('CREATE SCHEMA bronze');
GO

-- CRM: Customers (raw)
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.crm_cust_info (
        cst_id            NVARCHAR(50)  NULL,
        cst_key           NVARCHAR(50)  NULL,
        cst_firstname     NVARCHAR(200) NULL,
        cst_lastname      NVARCHAR(200) NULL,
        cst_marital_status NVARCHAR(50) NULL,
        cst_gender        NVARCHAR(50)  NULL,
        cst_create_date   NVARCHAR(50)  NULL
    );
END;
GO

-- CRM: Products (raw / historized)
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.crm_prd_info (
        prd_id        NVARCHAR(50)  NULL,
        prd_key       NVARCHAR(100) NULL,
        prd_nm        NVARCHAR(400) NULL,
        prd_cost      NVARCHAR(50)  NULL,
        prd_line      NVARCHAR(50)  NULL,
        prd_start_dt  NVARCHAR(50)  NULL,
        prd_end_dt    NVARCHAR(50)  NULL
    );
END;
GO

-- CRM: Sales details (raw)
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.crm_sales_details (
        sls_ord_num    NVARCHAR(50)  NULL,
        sls_prd_key    NVARCHAR(100) NULL,
        sls_cust_id    NVARCHAR(50)  NULL,
        sls_order_dt   NVARCHAR(50)  NULL,
        sls_ship_dt    NVARCHAR(50)  NULL,
        sls_due_dt     NVARCHAR(50)  NULL,
        sls_sales      NVARCHAR(50)  NULL,
        sls_quantity   NVARCHAR(50)  NULL,
        sls_price      NVARCHAR(50)  NULL
    );
END;
GO

-- ERP: Customer extra info (raw)
IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.erp_cust_az12 (
        cid         NVARCHAR(50)  NULL,
        bdate       NVARCHAR(50)  NULL,
        gen         NVARCHAR(50)  NULL
    );
END;
GO

-- ERP: Customer location (raw)
IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.erp_loc_a101 (
        cid      NVARCHAR(50)  NULL,
        cntry    NVARCHAR(100) NULL
    );
END;
GO

-- ERP: Product categories (raw)
IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.erp_px_cat_g1v2 (
        id           NVARCHAR(50)  NULL,
        cat          NVARCHAR(200) NULL,
        subcat       NVARCHAR(200) NULL,
        maintenance  NVARCHAR(50)  NULL
    );
END;
GO
