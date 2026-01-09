/*
===============================================================================
00_init_database
===============================================================================
Technical Objective: Initialise database schemas (bronze/silver/gold) and ETL logging to support governed warehouse execution.
===============================================================================
*/

/*
Purpose:
  Initialize database and schemas for the Data Warehouse project.

Notes:
  - Run this script as a user with CREATE DATABASE privileges.
  - If you are using an existing database, skip the CREATE DATABASE section
    and only run the schema creation.
*/

-- ===== Database (optional) =====
-- Uncomment and update the database name if required.
IF DB_ID(N'DataWarehouse') IS NULL
    BEGIN
        CREATE DATABASE DataWarehouse;
     END;
 GO

-- ===== Schemas =====
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bronze') EXEC('CREATE SCHEMA bronze');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver') EXEC('CREATE SCHEMA silver');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')   EXEC('CREATE SCHEMA gold');
GO

-- ===== Lightweight ETL run log (optional but recommended) =====
IF OBJECT_ID('dbo.etl_run_log', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.etl_run_log (
        etl_run_id      INT IDENTITY(1,1) PRIMARY KEY,
        layer_name      NVARCHAR(20)  NOT NULL,   -- bronze / silver / gold
        procedure_name  SYSNAME       NULL,
        start_time      DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME(),
        end_time        DATETIME2(0)  NULL,
        status          NVARCHAR(20)  NOT NULL DEFAULT N'RUNNING', -- RUNNING / SUCCESS / FAILED
        message         NVARCHAR(4000) NULL
    );
END;
GO
