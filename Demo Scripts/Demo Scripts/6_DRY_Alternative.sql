-----
-- A DRY Compromise?
USE AutoDealershipDemo;
GO










-----
-- Flattened Query again
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









-----
-- Inline Table Valued Function?
IF EXISTS(SELECT 1 FROM sys.objects WHERE objects.object_id = OBJECT_ID(N'dbo.itvf_CalcNetProfit'))
	DROP FUNCTION dbo.itvf_CalcNetProfit;
GO

CREATE FUNCTION dbo.itvf_CalcNetProfit (
	@SalesPersonID INT, 
	@CommissionRate DECIMAL(3, 2)
)
RETURNS TABLE
AS
RETURN (
	SELECT 
		SalesHistory.TransactionDate,
		SalesHistory.SellPrice - Inventory.InvoicePrice AS NetProfit,
		CASE
			WHEN (SalesHistory.SellPrice - Inventory.InvoicePrice) > 0
			THEN (SalesHistory.SellPrice - Inventory.InvoicePrice) * @CommissionRate
			WHEN (SalesHistory.SellPrice - Inventory.InvoicePrice) <= 0
			THEN 0
		END AS Commission
	FROM dbo.Inventory  
	INNER JOIN dbo.SalesHistory  
		ON SalesHistory.InventoryID = Inventory.InventoryID
	WHERE SalesHistory.SalesPersonID = @SalesPersonID
);
GO









-----
-- Compare & Contrast
-- Turn on Actual Execution Plan
-- DBCC FREEPROCCACHE
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

-- Inline Function
SELECT 
	SalesPerson.FirstName,
	SalesPerson.LastName,
	YEAR(itvf_CalcNetProfit.TransactionDate) AS YearSold,
	COUNT(1) AS AnnualNumOfSales,
	SUM(itvf_CalcNetProfit.NetProfit) AS DealerNetProfit,
	SUM(itvf_CalcNetProfit.Commission) AS Commission
FROM dbo.SalesPerson
CROSS APPLY dbo.itvf_CalcNetProfit(
		SalesPerson.SalesPersonID, 
		SalesPerson.CommissionRate
	) AS itvf_CalcNetProfit
GROUP BY 
	SalesPerson.LastName,
	SalesPerson.FirstName,
	YEAR(itvf_CalcNetProfit.TransactionDate)
ORDER BY 
	SalesPerson.LastName,
	SalesPerson.FirstName,
	YEAR(itvf_CalcNetProfit.TransactionDate);
GO

PRINT '-----';
GO

-- Flattened Query
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








-----
-- OPTIONAL
-- Beware of Multi-Statement Table Valued Functions
IF EXISTS(SELECT 1 FROM sys.objects WHERE objects.object_id = OBJECT_ID(N'dbo.mstvf_CalcNetProfit'))
	DROP FUNCTION dbo.mstvf_CalcNetProfit;
GO

CREATE FUNCTION dbo.mstvf_CalcNetProfit (
	@SalesPersonID INT, 
	@CommissionRate DECIMAL(3, 2)
)
RETURNS @CalNetProfit TABLE (
	TransactionDate DATETIME,
	NetProfit DECIMAL(14, 4),
	Commission DECIMAL(14, 4)
)
AS
BEGIN
	INSERT INTO @CalNetProfit (
		TransactionDate,
		NetProfit,
		Commission
	)
	SELECT 
		SalesHistory.TransactionDate,
		SalesHistory.SellPrice - Inventory.InvoicePrice AS NetProfit,
		CASE
			WHEN (SalesHistory.SellPrice - Inventory.InvoicePrice) > 0
			THEN (SalesHistory.SellPrice - Inventory.InvoicePrice) * @CommissionRate
			WHEN (SalesHistory.SellPrice - Inventory.InvoicePrice) <= 0
			THEN 0
		END AS Commission
	FROM dbo.Inventory  
	INNER JOIN dbo.SalesHistory  
		ON SalesHistory.InventoryID = Inventory.InventoryID
	WHERE SalesHistory.SalesPersonID = @SalesPersonID;

	RETURN
END
GO









-----
-- Compare & Contrast
-- Turn on Actual Execution Plan
-- DBCC FREEPROCCACHE
ALTER EVENT SESSION [TSQL_Batch_StartStop]  
ON SERVER  
STATE = START;
GO
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

-- Multi-Statement Table Valued Function
SELECT 
	SalesPerson.FirstName,
	SalesPerson.LastName,
	YEAR(mstvf_CalcNetProfit.TransactionDate) AS YearSold,
	COUNT(1) AS AnnualNumOfSales,
	SUM(mstvf_CalcNetProfit.NetProfit) AS DealerNetProfit,
	SUM(mstvf_CalcNetProfit.Commission) AS Commission
FROM dbo.SalesPerson
CROSS APPLY dbo.mstvf_CalcNetProfit(
		SalesPerson.SalesPersonID, 
		SalesPerson.CommissionRate
	) AS mstvf_CalcNetProfit
GROUP BY 
	SalesPerson.LastName,
	SalesPerson.FirstName,
	YEAR(mstvf_CalcNetProfit.TransactionDate)
ORDER BY 
	SalesPerson.LastName,
	SalesPerson.FirstName,
	YEAR(mstvf_CalcNetProfit.TransactionDate);
GO

PRINT '-----';
GO

-- Flattened Query
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
-- Clean-Up
ALTER EVENT SESSION [TSQL_Batch_StartStop]  
ON SERVER  
STATE = STOP;
GO