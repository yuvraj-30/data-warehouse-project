/*
===============================================================================
05_ddl_gold
===============================================================================
Business Objective:
  Create a GOLD star schema as TABLES (dimensions + fact) for BI consumption.
  This aligns with typical ERP/wholesale analytics patterns:
    - Stable surrogate keys in dimensions
    - Fact table references dimensions (FKs)
    - Business keys retained for traceability and easier ad-hoc joins
===============================================================================
*/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold') EXEC('CREATE SCHEMA gold');
GO

/*---------------------------------------------------------------------------
Drop (safe) in dependency order
---------------------------------------------------------------------------*/
IF OBJECT_ID('gold.fact_sales_rejects', 'U') IS NOT NULL DROP TABLE gold.fact_sales_rejects;
IF OBJECT_ID('gold.fact_sales', 'U') IS NOT NULL DROP TABLE gold.fact_sales;
IF OBJECT_ID('gold.dim_products', 'U') IS NOT NULL DROP TABLE gold.dim_products;
IF OBJECT_ID('gold.dim_customers', 'U') IS NOT NULL DROP TABLE gold.dim_customers;
GO

/*---------------------------------------------------------------------------
Dimensions
---------------------------------------------------------------------------*/
CREATE TABLE gold.dim_customers (
    customer_sk      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_gold_dim_customers PRIMARY KEY,
    customer_id      INT               NOT NULL,                 -- CRM cst_id
    customer_key     NVARCHAR(50)      NOT NULL,                 -- CRM cst_key (business key)
    first_name       NVARCHAR(200)     NULL,
    last_name        NVARCHAR(200)     NULL,
    marital_status   NVARCHAR(50)      NULL,
    gender           NVARCHAR(50)      NULL,
    birthdate        DATE              NULL,                     -- ERP enrichment
    country          NVARCHAR(100)     NULL,                     -- ERP enrichment
    create_date      DATE              NULL                      -- CRM cst_create_date
);
GO

CREATE UNIQUE INDEX UX_gold_dim_customers_customer_key ON gold.dim_customers(customer_key);
CREATE UNIQUE INDEX UX_gold_dim_customers_customer_id  ON gold.dim_customers(customer_id);
GO

CREATE TABLE gold.dim_products (
    product_sk     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_gold_dim_products PRIMARY KEY,
    product_key    NVARCHAR(50)      NOT NULL,                   -- canonical key (e.g., FR-R92B-58)
    product_id     INT               NOT NULL,                   -- CRM prd_id
    product_name   NVARCHAR(400)     NULL,
    category_id    NVARCHAR(50)      NULL,                       -- ERP ref key (e.g., CO_RF)
    category       NVARCHAR(200)     NULL,
    subcategory    NVARCHAR(200)     NULL,
    maintenance    NVARCHAR(50)      NULL,
    cost           DECIMAL(18,2)     NOT NULL DEFAULT (0),
    product_line   NVARCHAR(50)      NULL,
    start_date     DATE              NULL,
    end_date       DATE              NULL
);
GO

CREATE UNIQUE INDEX UX_gold_dim_products_product_key ON gold.dim_products(product_key);
GO

/*---------------------------------------------------------------------------
Fact + rejects
---------------------------------------------------------------------------*/
CREATE TABLE gold.fact_sales (
    sales_sk        BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_gold_fact_sales PRIMARY KEY,
    order_number    NVARCHAR(50)  NOT NULL,
    order_date      DATE          NULL,
    shipping_date   DATE          NULL,
    due_date        DATE          NULL,
    sales_amount    DECIMAL(18,2) NULL,
    quantity        INT           NULL,
    price           DECIMAL(18,2) NULL,

    -- business keys for easy reporting joins
    customer_key    NVARCHAR(50)  NOT NULL,
    product_key     NVARCHAR(50)  NOT NULL,

    -- surrogate keys for model integrity
    customer_sk     INT           NOT NULL,
    product_sk      INT           NOT NULL
);
GO

ALTER TABLE gold.fact_sales
    ADD CONSTRAINT FK_gold_fact_sales_customer_sk
        FOREIGN KEY (customer_sk) REFERENCES gold.dim_customers(customer_sk);

ALTER TABLE gold.fact_sales
    ADD CONSTRAINT FK_gold_fact_sales_product_sk
        FOREIGN KEY (product_sk) REFERENCES gold.dim_products(product_sk);
GO

-- optional: prevent exact duplicates on business grain
CREATE UNIQUE INDEX UX_gold_fact_sales_grain
ON gold.fact_sales(order_number, product_key, customer_key);
GO

CREATE TABLE gold.fact_sales_rejects (
    reject_sk       BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_gold_fact_sales_rejects PRIMARY KEY,
    order_number    NVARCHAR(50)  NULL,
    order_date      DATE          NULL,
    shipping_date   DATE          NULL,
    due_date        DATE          NULL,
    sales_amount    DECIMAL(18,2) NULL,
    quantity        INT           NULL,
    price           DECIMAL(18,2) NULL,

    customer_id     INT           NULL,
    product_key_raw NVARCHAR(50)  NULL,

    reject_reason   NVARCHAR(400) NOT NULL,
    rejected_at     DATETIME2     NOT NULL DEFAULT (SYSDATETIME())
);
GO
