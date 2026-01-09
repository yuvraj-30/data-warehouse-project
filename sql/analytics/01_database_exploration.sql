USE DataWarehouseAnalytics;
GO

/*
===============================================================================
01_database_exploration
===============================================================================
Purpose:
  Quick discovery of tables/views and their columns for the Analytics database.

Notes:
  - Uses SYS catalog views (preferred over INFORMATION_SCHEMA for SQL Server specifics).
===============================================================================
*/

-- List user tables and views
SELECT
    s.name  AS [schema_name],
    o.name  AS [object_name],
    o.type_desc
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type IN ('U','V')
ORDER BY s.name, o.name;

-- Column metadata for a given object (edit the name as needed)
DECLARE @schema SYSNAME = N'analytics_gold';
DECLARE @object SYSNAME = N'vw_dim_customers';

SELECT
    c.column_id,
    c.name AS column_name,
    t.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable
FROM sys.columns c
JOIN sys.objects o ON o.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
JOIN sys.types t   ON t.user_type_id = c.user_type_id
WHERE s.name = @schema
  AND o.name = @object
ORDER BY c.column_id;
