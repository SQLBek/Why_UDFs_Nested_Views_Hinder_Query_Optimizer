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
-- Inline User Defined Function
IF EXISTS(SELECT 1 FROM sys.objects WHERE objects.object_id = OBJECT_ID(N'dbo.ilf_CalcNetProfit'))
	DROP FUNCTION dbo.ilf_CalcNetProfit;
GO

CREATE FUNCTION dbo.ilf_CalcNetProfit (
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
	YEAR(ilf_CalcNetProfit.TransactionDate) AS YearSold,
	COUNT(1) AS AnnualNumOfSales,
	SUM(ilf_CalcNetProfit.NetProfit) AS DealerNetProfit,
	SUM(ilf_CalcNetProfit.Commission) AS Commission
FROM dbo.SalesPerson
CROSS APPLY dbo.ilf_CalcNetProfit(
		SalesPerson.SalesPersonID, 
		SalesPerson.CommissionRate
	) AS ilf_CalcNetProfit
GROUP BY 
	SalesPerson.LastName,
	SalesPerson.FirstName,
	YEAR(ilf_CalcNetProfit.TransactionDate)
ORDER BY 
	SalesPerson.LastName,
	SalesPerson.FirstName,
	YEAR(ilf_CalcNetProfit.TransactionDate);
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