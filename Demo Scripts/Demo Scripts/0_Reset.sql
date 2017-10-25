USE Master;
GO
ALTER DATABASE AutoDealershipDemo
SET COMPATIBILITY_LEVEL = 120
GO
USE AutoDealershipDemo;
GO
DBCC FREEPROCCACHE
GO
--
-- IMPORTANT: PRE-STAGE & EXECUTE SCRIPT #5
--

-- EXEC master.dbo.xp_cmdshell 'DIR F:\ && DEL F:\TSQL_*.xel && DIR F:\';
-- GO
-- sudo ls -al /var/opt/mssql/XE/
-- sudo rm -f /var/opt/mssql/XE/TSQL_*.xel

-- Rebuild all indexes
SELECT 
	'ALTER INDEX ALL ON ' 
	+ QUOTENAME(schemas.name) 
	+ '.' 
	+ QUOTENAME(objects.name) 
	+ ' REBUILD WITH (FILLFACTOR = 75);'
FROM sys.objects
INNER JOIN sys.schemas
	ON schemas.schema_id = objects.schema_id
WHERE objects.type = 'U';
GO

-- EXEC sp_configure 'show advanced options', 1
-- RECONFIGURE
-- EXEC sp_configure 'xp_cmdshell', 1
-- RECONFIGURE

-- CHECK FILEPATH!!!
-- Clean-up
-- MYSTIQUE
-- EXEC master.dbo.xp_cmdshell 'DIR F:\ && DEL F:\XE_*.xel && DIR F:\';
-- CABLE
-- C:\var\opt\mssql\XE\
--EXEC master.dbo.xp_cmdshell 'DIR C:\var\opt\mssql\XE\ && DEL C:\var\opt\mssql\XE\XE_*.xel && C:\var\opt\mssql\XE\';

-- Reset Database Compatibility Level
ALTER DATABASE [AutoDealershipDemo] SET COMPATIBILITY_LEVEL = 140;

-- Force Query Optimizer to pre-2012
--DBCC TRACEON (9481, -1)
DBCC TRACESTATUS

-- Set XE Event File to Display:
-- Name, Timestamp, SQL_Text, Statement, Duration, Logical Reads

SELECT schemas.name, objects.name, indexes.name, indexes.is_disabled,
	'ALTER INDEX ' 
	+ QUOTENAME(indexes.name) 
	+ ' ON ' + QUOTENAME(schemas.name) + '.' + QUOTENAME(objects.name)
	+ ' DISABLE;' 
	AS DisableCmd,
	'UPDATE STATISTICS ' 
	+ QUOTENAME(schemas.name) + '.' + QUOTENAME(objects.name)
	+ SPACE(1) 
	+ QUOTENAME(indexes.name) 
	+ ' WITH SAMPLE 75 PERCENT;'
	AS UpdateStats,
	'DBCC SHOW_STATISTICS ('''
	+ QUOTENAME(schemas.name) + '.' + QUOTENAME(objects.name)
	+ ''', '
	+ QUOTENAME(indexes.name) 
	+ ');'
	AS ShowStatistics,
	'ALTER INDEX ' 
	+ QUOTENAME(indexes.name) 
	+ ' ON ' + QUOTENAME(schemas.name) + '.' + QUOTENAME(objects.name)
	+ ' REBUILD;' 
	AS EnableCmd

FROM sys.indexes
INNER JOIN sys.objects
	ON objects.object_id = indexes.object_id
INNER JOIN sys.schemas
	ON schemas.schema_id = objects.schema_id
WHERE objects.type = 'U'
	AND objects.name <> 'InventoryFlat'
	AND indexes.type_desc = 'NONCLUSTERED'
	AND schemas.name <> 'Cardinality'


----------------------
----------------------
ALTER INDEX ALL ON [Vehicle].[Make] REBUILD WITH (FILLFACTOR = 75);
ALTER INDEX ALL ON [Vehicle].[Model] REBUILD WITH (FILLFACTOR = 75);
ALTER INDEX ALL ON [Vehicle].[Color] REBUILD WITH (FILLFACTOR = 75);
ALTER INDEX ALL ON [Vehicle].[BaseModel] REBUILD WITH (FILLFACTOR = 75);
ALTER INDEX ALL ON [Vehicle].[Package] REBUILD WITH (FILLFACTOR = 75);
ALTER INDEX ALL ON [dbo].[Inventory] REBUILD WITH (FILLFACTOR = 75);
ALTER INDEX ALL ON [dbo].[SalesHistory] REBUILD WITH (FILLFACTOR = 75);
ALTER INDEX ALL ON [dbo].[SalesPerson] REBUILD WITH (FILLFACTOR = 75);
ALTER INDEX ALL ON [dbo].[Customer] REBUILD WITH (FILLFACTOR = 75);
ALTER INDEX ALL ON [dbo].[InventoryFlat] REBUILD WITH (FILLFACTOR = 75);
ALTER INDEX ALL ON [Vehicle].[Classification] REBUILD WITH (FILLFACTOR = 75);
--ALTER INDEX ALL ON [Cardinality].[Alpha] REBUILD WITH (FILLFACTOR = 75);
--ALTER INDEX ALL ON [Cardinality].[Bravo] REBUILD WITH (FILLFACTOR = 75);
--ALTER INDEX ALL ON [Cardinality].[Charlie] REBUILD WITH (FILLFACTOR = 75);
--ALTER INDEX ALL ON [Cardinality].[Delta] REBUILD WITH (FILLFACTOR = 75);
--ALTER INDEX ALL ON [Cardinality].[Echo] REBUILD WITH (FILLFACTOR = 75);
--ALTER INDEX ALL ON [Cardinality].[Foxtrot] REBUILD WITH (FILLFACTOR = 75);
--ALTER INDEX ALL ON [Cardinality].[Golf] REBUILD WITH (FILLFACTOR = 75);
--ALTER INDEX ALL ON [Cardinality].[Hotel] REBUILD WITH (FILLFACTOR = 75);
GO

UPDATE STATISTICS [Vehicle].[Make] [CK_Vehicle_Make_MakeID] WITH SAMPLE 75 PERCENT;
UPDATE STATISTICS [Vehicle].[Model] [CK_Vehicle_Model_ModelID] WITH SAMPLE 75 PERCENT;
UPDATE STATISTICS [Vehicle].[Color] [CK_Vehicle_Color_ColorID] WITH SAMPLE 75 PERCENT;
UPDATE STATISTICS [Vehicle].[BaseModel] [CK_Vehicle_BaseModel_BaseModelID] WITH SAMPLE 75 PERCENT;
UPDATE STATISTICS [Vehicle].[BaseModel] [UI_Vehicle_BaseModel_MakeModelColorID] WITH SAMPLE 75 PERCENT;
UPDATE STATISTICS [Vehicle].[Package] [CK_Vehicle_Package_PackageID] WITH SAMPLE 75 PERCENT;
UPDATE STATISTICS [dbo].[Inventory] [CK_Inventory_InventoryID] WITH SAMPLE 75 PERCENT;
UPDATE STATISTICS [dbo].[Inventory] [IX_Inventory_VIN] WITH SAMPLE 75 PERCENT;
UPDATE STATISTICS [dbo].[SalesHistory] [CK_SalesHistory_SalesHistoryID] WITH SAMPLE 75 PERCENT;
UPDATE STATISTICS [dbo].[SalesHistory] [IX_SalesHistory_CustomerID] WITH SAMPLE 75 PERCENT;
UPDATE STATISTICS [dbo].[SalesHistory] [IX_SalesHistory_InventoryID] WITH SAMPLE 75 PERCENT;
UPDATE STATISTICS [dbo].[SalesHistory] [IX_SalesHistory_SalesPersonID] WITH SAMPLE 75 PERCENT;
UPDATE STATISTICS [dbo].[SalesPerson] [CK_SalesPerson_SalesPersonID] WITH SAMPLE 75 PERCENT;
UPDATE STATISTICS [dbo].[Customer] [CK_Customer_CustomerID] WITH SAMPLE 75 PERCENT;
UPDATE STATISTICS [Vehicle].[Classification] [CK_Vehicle_Classification_ClassificationID] WITH SAMPLE 75 PERCENT;
----
/*
ALTER INDEX [UI_Vehicle_BaseModel_MakeModelColorID] ON [Vehicle].[BaseModel] ENABLE;
ALTER INDEX [IX_SalesHistory_CustomerID] ON [dbo].[SalesHistory] ENABLE;
ALTER INDEX [IX_SalesHistory_SalesPersonID] ON [dbo].[SalesHistory] ENABLE;
ALTER INDEX [IX_Inventory_VIN] ON [dbo].[Inventory] ENABLE;
ALTER INDEX [IX_SalesHistory_InventoryID] ON [dbo].[SalesHistory] ENABLE;
*/

GO
-----
-- Reset SalesPerson Profit values
WITH NewProfits_CTE AS (
	SELECT 
		SalesHistory.SalesHistoryID,
		Inventory.InventoryID,
		--SalesHistory.SellPrice,
		Inventory.InvoicePrice,
		(SalesHistory.SellPrice - Inventory.InvoicePrice) AS DealerNetProfit,
		-- Give me a random value between 0 and 10
		((RAND(CHECKSUM(NEWID())) * 10) - 5) / 100 AS ProfitMarginPct
	FROM dbo.Inventory  
	INNER JOIN dbo.SalesHistory  
		ON SalesHistory.InventoryID = Inventory.InventoryID
)
UPDATE dbo.SalesHistory
SET SalesHistory.SellPrice = (NewProfits_CTE.InvoicePrice * NewProfits_CTE.ProfitMarginPct) + NewProfits_CTE.InvoicePrice
FROM NewProfits_CTE
WHERE NewProfits_CTE.SalesHistoryID = SalesHistory.SalesHistoryID;
GO