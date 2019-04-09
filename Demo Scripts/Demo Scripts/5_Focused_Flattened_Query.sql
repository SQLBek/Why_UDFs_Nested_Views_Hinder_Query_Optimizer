-- TURN ON ACTUAL EXECUTION PLAN
--
-- Execute all immediately or pre-stage
USE AutoDealershipDemo;
DBCC FREEPROCCACHE
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO








-----
-- Final Flat Query
-- Only putting into a view for demo readability
IF EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'dbo.vw_SalesPerson_AnnualProfit_Flattened'))
	DROP VIEW dbo.vw_SalesPerson_AnnualProfit_Flattened;
GO
CREATE VIEW dbo.vw_SalesPerson_AnnualProfit_Flattened  
AS  
SELECT 
	SalesPerson.FirstName,
	SalesPerson.LastName,
	YEAR(SalesHistory.TransactionDate) AS YearSold,
	SUM(SalesHistory.SellPrice - Inventory.InvoicePrice) AS DealerNetProfit,
	SUM(CASE
		WHEN (SalesHistory.SellPrice - Inventory.InvoicePrice) > 0
		THEN (SalesHistory.SellPrice - Inventory.InvoicePrice) * SalesPerson.CommissionRate
		WHEN (SalesHistory.SellPrice - Inventory.InvoicePrice) <= 0
		THEN 0
	END) AS Commission,
	COUNT(SalesHistory.SalesHistoryID) AS AnnualNumOfSales
FROM dbo.Inventory  
INNER JOIN dbo.SalesHistory  
	ON SalesHistory.InventoryID = Inventory.InventoryID
INNER JOIN dbo.SalesPerson
	ON SalesHistory.SalesPersonID = SalesPerson.SalesPersonID
GROUP BY 
	SalesPerson.LastName,
	SalesPerson.FirstName,
	YEAR(SalesHistory.TransactionDate);
GO
PRINT '-----'








-----
-- Run NoUDF query as Baseline
-- OPTIONAL: Spin up workload
-- DBCC FREEPROCCACHE
SELECT 
	FirstName,
	LastName,
	YearSold,
	AnnualNumOfSales,
	DealerNetProfit,
	Commission
FROM dbo.vw_SalesPerson_AnnualProfit_NoUDF
ORDER BY 
	LastName, 
	FirstName, 
	YearSold;

PRINT '-----';
GO


-----
-- Run Flattened Query
-- DBCC FREEPROCCACHE
SELECT 
	FirstName,
	LastName,
	YearSold,
	AnnualNumOfSales,
	DealerNetProfit,
	Commission
FROM dbo.vw_SalesPerson_AnnualProfit_Flattened
ORDER BY 
	LastName, 
	FirstName, 
	YearSold;

PRINT '-----';
GO




-----
-- What differs?
--
-- * parse & compile times
-- * logical reads
-- * actual execution time


-----
-- Turn on Actual Execution Plan & re-run both
-- Look at Properties
-- * estimated subtree cost
-- * estimated row count
-- * memory grant
-- * optimization level
-- * cached plan size
--
