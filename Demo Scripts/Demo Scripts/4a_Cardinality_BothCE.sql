/*
CHANGING CARDINALITY ESTIMATOR SQL Server 2014
TRACE FLAG REFERENCE:

TF 9481
Use when running SQL Server 2014 with the default database compatibility level 120. Trace flag 9481 forces the query optimizer to use version 70 (the SQL Server 2012 version) of the cardinality estimator when creating the query plan.

TF 2312	
Use when running SQL Server 2014 with database compatibility level 110, which is the compatibility level for SQL Server 2012. Trace flag 2312 forces the query optimizer to use version 120 (the SQL Server 2014 version) of the cardinality estimator when creating the query plan.

NOTE: SQL Server 2016 introduces Database Scoped Configurations to manage

-- Check current state
SELECT name, compatibility_level, @@VERSION
FROM sys.databases
WHERE name = 'AutoDealershipDemo'

-- Adjust if necessary
USE [master]

-- 2008R2
ALTER DATABASE [AutoDealershipDemo] SET COMPATIBILITY_LEVEL = 100

-- 2012
ALTER DATABASE [AutoDealershipDemo] SET COMPATIBILITY_LEVEL = 110

-- 2014
ALTER DATABASE [AutoDealershipDemo] SET COMPATIBILITY_LEVEL = 120

-- Must flush to ensure plans recompiled with proper CE setting
DBCC FREEPROCCACHE

USE AutoDealershipDemo;
*/








-----
-- Nested Level: Cardinality Demo
USE AutoDealershipDemo;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
DBCC FREEPROCCACHE;
GO








-----
-- Expand this view: dbo.BaseVw_InventorySalesHistory_All
EXEC sp_helpExpandView @ViewName = 'dbo.BaseVw_InventorySalesHistory_All',
	@OutputFormat = 'Horizontal',
	@ShowObjectCount = 1;








-----
-- Analyze a nested view with both CEs
-- Turn on Actual Execution Plan
PRINT '-- Use Legacy CE';
SELECT *
FROM dbo.BaseVw_InventorySalesHistory_All
WHERE PackageName = 'Extra Luxury Edition'
OPTION (QUERYTRACEON 9481);
PRINT '-----';
GO

PRINT '-- Use current 2014 CE';
SELECT *
FROM dbo.BaseVw_InventorySalesHistory_All
WHERE PackageName = 'Extra Luxury Edition';
GO




-----
-- Open Properties
-- estimated row count
-- estimated subtree cost
-- optimization level
-- 
-- Record Parse & Compile Time:
-- xxxx
-- Record Elapsed Time:
-- xxxx









-----
-- Focused specific query
DBCC FREEPROCCACHE;
GO
PRINT '-- Use Legacy CE';
SELECT *
FROM dbo.Inventory
INNER JOIN Vehicle.Package
	ON Inventory.PackageID = Package.PackageID
INNER JOIN Vehicle.BaseModel
	ON BaseModel.BaseModelID = Inventory.BaseModelID
INNER JOIN Vehicle.Make
	ON BaseModel.MakeID = Make.MakeID
INNER JOIN Vehicle.Model
	ON BaseModel.ModelID = Model.ModelID
INNER JOIN Vehicle.Color
	ON BaseModel.ColorID = Color.ColorID
INNER JOIN dbo.SalesHistory
	ON SalesHistory.InventoryID = Inventory.InventoryID
INNER JOIN dbo.Customer
	ON Customer.CustomerID = SalesHistory.CustomerID
INNER JOIN dbo.SalesPerson
	ON SalesPerson.SalesPersonID = SalesHistory.SalesPersonID
WHERE PackageName = 'Extra Luxury Edition'
OPTION (QUERYTRACEON 9481);
PRINT '-----';
GO

PRINT '-- Use Current CE';
SELECT *
FROM dbo.Inventory
INNER JOIN Vehicle.Package
	ON Inventory.PackageID = Package.PackageID
INNER JOIN Vehicle.BaseModel
	ON BaseModel.BaseModelID = Inventory.BaseModelID
INNER JOIN Vehicle.Make
	ON BaseModel.MakeID = Make.MakeID
INNER JOIN Vehicle.Model
	ON BaseModel.ModelID = Model.ModelID
INNER JOIN Vehicle.Color
	ON BaseModel.ColorID = Color.ColorID
INNER JOIN dbo.SalesHistory
	ON SalesHistory.InventoryID = Inventory.InventoryID
INNER JOIN dbo.Customer
	ON Customer.CustomerID = SalesHistory.CustomerID
INNER JOIN dbo.SalesPerson
	ON SalesPerson.SalesPersonID = SalesHistory.SalesPersonID
WHERE PackageName = 'Extra Luxury Edition';
GO




-----
-- Open Properties
-- re-compare timings
-- estimated row count
-- estimated subtree cost
-- optimization level