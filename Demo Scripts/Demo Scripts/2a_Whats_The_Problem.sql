/*
REPORT REQUIREMENT:

On an Annualized Basis: 
For each Sales Person:

- How many vehicles did each sales person sell?
- How much profit did each net for the dealership?
- How much commission did we pay out to each Sales Person?
*/
USE AutoDealershipDemo;
GO








-----
-- CFO wants to see ALL the data!
-- Look at Estimated Exec Plan
SELECT 
	FirstName,
	LastName,
	YearSold,
	DealerNetProfit,
	Commission,
	AnnualNumOfSales
FROM dbo.vw_SalesPerson_AnnualProfit
ORDER BY 
	LastName,
	YearSold;








-----
-- Extended Events!
-- Show TSQL_Tuning XE Definition
-- Check STATISTICS IO, check XE
DBCC FREEPROCCACHE
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO


-----
-- Clean-up
-- EXEC master.dbo.xp_cmdshell 'DIR F:\ && DEL F:\TSQL_*.xel && DIR F:\';
-- GO
-- sudo ls -al /var/opt/mssql/XE/
-- sudo rm -f /var/opt/mssql/XE/TSQL_*.xel
ALTER EVENT SESSION [TSQL_Batch_StartStop]  
ON SERVER  
STATE = START;
GO
ALTER EVENT SESSION [TSQL_Statement_Completed]  
ON SERVER  
STATE = START;
GO




SELECT 
	FirstName,
	LastName,
	YearSold,
	DealerNetProfit,
	Commission,
	AnnualNumOfSales
FROM dbo.vw_SalesPerson_AnnualProfit
-- Add predicate filter to we get result back
WHERE YearSold = 2016
	AND LastName = 'Gilbert'
ORDER BY 
	LastName,
	YearSold;





-- About XX logical reads






-----
-- Impact of scalar UDFs are hidden!
-- Let's look at simpler example query
-- Check STATISTICS IO, check XE
SELECT TOP 100
	Inventory.InventoryID,
	Inventory.VIN,
	dbo.udf_CalcNetProfit(Inventory.VIN)
FROM dbo.Inventory
INNER JOIN SalesHistory
	ON SalesHistory.InventoryID = Inventory.InventoryID;








-----
-- How can we deal with this?
-- What's really inside dbo.udf_CalcNetProfit?
IF EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'dbo.udf_CalcNetProfit'))
	DROP FUNCTION dbo.udf_CalcNetProfit;
GO
CREATE FUNCTION dbo.udf_CalcNetProfit (  
	@VIN CHAR(17)  
)  
RETURNS money  
AS  
BEGIN  
	DECLARE @NetProfit MONEY;  
  
	SELECT @NetProfit = SalesHistory.SellPrice - Inventory.InvoicePrice   
	FROM dbo.BaseVw_SalesHistory AS SalesHistory  
	INNER JOIN dbo.BaseVw_Inventory AS Inventory  
		ON SalesHistory.InventoryID = Inventory.InventoryID  
	WHERE Inventory.VIN = @VIN;  
  
	RETURN @NetProfit;  
END  
  
  
  





-----
-- Break-out Code?
-- Write a situation specific, focused query.
SELECT 
	Inventory.InventoryID,
	Inventory.VIN,
	SalesHistory.SellPrice - Inventory.InvoicePrice   
FROM dbo.Inventory
INNER JOIN SalesHistory
	ON SalesHistory.InventoryID = Inventory.InventoryID;
GO




-- About XX logical reads







-----
-- Return to Original Example
IF EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'dbo.vw_SalesPerson_AnnualProfit_NoUDF'))
	DROP VIEW dbo.vw_SalesPerson_AnnualProfit_NoUDF;
GO
CREATE VIEW dbo.vw_SalesPerson_AnnualProfit_NoUDF
AS
SELECT 
	SalesPerson.FirstName,
	SalesPerson.LastName,
	AnnualNumOfSales.YearSold,
	SUM(SalesHistory.SellPrice - vw_AllSoldInventory.InvoicePrice) AS DealerNetProfit,
	SUM(CASE
		WHEN (SalesHistory.SellPrice - vw_AllSoldInventory.InvoicePrice) > 0
		THEN (SalesHistory.SellPrice - vw_AllSoldInventory.InvoicePrice) * SalesPerson.CommissionRate
		WHEN (SalesHistory.SellPrice - vw_AllSoldInventory.InvoicePrice) <= 0
		THEN 0
	END) AS Commission,
	AnnualNumOfSales.AnnualNumOfSales
FROM dbo.vw_AllSoldInventory
INNER JOIN dbo.BaseVw_SalesHistory AS SalesHistory
	ON vw_AllSoldInventory.SalesHistoryID = SalesHistory.SalesHistoryID
INNER JOIN dbo.BaseVw_SalesPerson AS SalesPerson
	ON SalesHistory.SalesPersonID = SalesPerson.SalesPersonID
INNER JOIN dbo.vw_SalesPerson_AnnualNumOfSales AS AnnualNumOfSales
	ON SalesPerson.SalesPersonID = AnnualNumOfSales.SalespersonID
	AND YEAR(vw_AllSoldInventory.TransactionDate) = AnnualNumOfSales.YearSold
GROUP BY 
	SalesPerson.LastName,
	SalesPerson.FirstName,
	AnnualNumOfSales.YearSold,	
	AnnualNumOfSales.AnnualNumOfSales
GO








-----
-- Run View Query
SELECT 
	FirstName,
	LastName,
	YearSold,
	DealerNetProfit,
	Commission,
	AnnualNumOfSales
FROM dbo.vw_SalesPerson_AnnualProfit_NoUDF
WHERE YearSold = 2016
	AND LastName = 'Gilbert'
ORDER BY 
	LastName,
	YearSold;
GO








-----
-- Look at STATISTICS IO OUTPUT
-- Something strange here.  
-- Why are we even querying BaseModel & Package tables?


-----
-- Clean-Up
ALTER EVENT SESSION [TSQL_Batch_StartStop]  
ON SERVER  
STATE = STOP;
GO
ALTER EVENT SESSION [TSQL_Statement_Completed]  
ON SERVER  
STATE = STOP;
GO
-- EXEC master.dbo.xp_cmdshell 'DIR F:\ && DEL F:\TSQL_*.xel && DIR F:\';
-- GO
-- sudo ls -al /var/opt/mssql/XE/
-- sudo rm -f /var/opt/mssql/XE/TSQL_*.xel