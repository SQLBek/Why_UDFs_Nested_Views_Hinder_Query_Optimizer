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
-- How many vehicles did each sales person sell?
-- There's a view for that!
SELECT TOP 100
	vw_SalesPerson_SalesPerMonth.FirstName,
	vw_SalesPerson_SalesPerMonth.LastName,
	vw_SalesPerson_SalesPerMonth.MonthYearSold,
	vw_SalesPerson_SalesPerMonth.NumOfSales,
	vw_SalesPerson_SalesPerMonth.SalesPersonID
FROM dbo.vw_SalesPerson_SalesPerMonth;








-----
-- Using that view, we can write an annualized query
SELECT TOP 100
	vw_SalesPerson_SalesPerMonth.FirstName,
	vw_SalesPerson_SalesPerMonth.LastName,
	YEAR(vw_SalesPerson_SalesPerMonth.MonthYearSold) AS YearSold,
	SUM(NumOfSales) AS AnnualNumOfSales,
	vw_SalesPerson_SalesPerMonth.SalesPersonID
FROM dbo.vw_SalesPerson_SalesPerMonth
GROUP BY
	vw_SalesPerson_SalesPerMonth.SalesPersonID,
	vw_SalesPerson_SalesPerMonth.FirstName,
	vw_SalesPerson_SalesPerMonth.LastName,
	YEAR(vw_SalesPerson_SalesPerMonth.MonthYearSold)
ORDER BY
	vw_SalesPerson_SalesPerMonth.FirstName,
	vw_SalesPerson_SalesPerMonth.LastName,
	YearSold;








-----
-- That's really useful! Let's wrap that up in a quick 
-- view for reuse later!
IF EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'dbo.vw_SalesPerson_AnnualNumOfSales'))
	DROP VIEW dbo.vw_SalesPerson_AnnualNumOfSales;
GO
CREATE VIEW dbo.vw_SalesPerson_AnnualNumOfSales
AS
SELECT 
	vw_SalesPerson_SalesPerMonth.FirstName,
	vw_SalesPerson_SalesPerMonth.LastName,
	YEAR(vw_SalesPerson_SalesPerMonth.MonthYearSold) AS YearSold,
	SUM(NumOfSales) AS AnnualNumOfSales,
	vw_SalesPerson_SalesPerMonth.SalesPersonID
FROM dbo.vw_SalesPerson_SalesPerMonth
GROUP BY
	vw_SalesPerson_SalesPerMonth.SalesPersonID,
	vw_SalesPerson_SalesPerMonth.FirstName,
	vw_SalesPerson_SalesPerMonth.LastName,
	YEAR(vw_SalesPerson_SalesPerMonth.MonthYearSold);
GO








-----
-- How much profit did each Sales Person net for the dealership?
-- We have a view to show all inventory sold.
-- We have a UDF to calculate Net Profit based on VIN.
SELECT TOP 100
	vw_AllSoldInventory.VIN,
	vw_AllSoldInventory.InvoicePrice,
	vw_AllSoldInventory.SellPrice,
	dbo.udf_CalcNetProfit(VIN) AS NetProfit,
	vw_AllSoldInventory.TransactionDate,
	vw_AllSoldInventory.SalesHistoryID
FROM dbo.vw_AllSoldInventory;








-----
-- How much commission did we pay out to each Sales Person?
-- Well, commission rate is shown on SalesPerson table
SELECT TOP 100
	SalesPerson.SalesPersonID,
	SalesPerson.FirstName,
	SalesPerson.LastName,
	SalesPerson.CommissionRate
FROM dbo.BaseVw_SalesPerson AS SalesPerson;








-----
-- What's up with BaseVw_*
-- Architect says every table must have a corresponding view
-- Why?  Abstraction & security!  No one should ever query a 
-- table, only a view.  Those are the rules!
SELECT objects.name AS TableName, views.ViewName
FROM sys.objects
INNER JOIN (
	SELECT objects.name AS ViewName
	FROM sys.objects
	WHERE objects.type = 'V'
) views
	ON 'BaseVw_' + objects.name = views.ViewName
WHERE objects.type = 'U'
ORDER BY TableName;








-----
-- Bring it together!
SELECT 
	SalesPerson.FirstName,
	SalesPerson.LastName,
	AnnualNumOfSales.YearSold,
	SUM(dbo.udf_CalcNetProfit(vw_AllSoldInventory.VIN)) AS DealerNetProfit,
	-- Byron: Need to wrap the Commission calculation into a new UDF for reuse later
	SUM(CASE
		WHEN dbo.udf_CalcNetProfit(vw_AllSoldInventory.VIN) > 0
			THEN dbo.udf_CalcNetProfit(vw_AllSoldInventory.VIN) * SalesPerson.CommissionRate
		WHEN dbo.udf_CalcNetProfit(vw_AllSoldInventory.VIN) <= 0
			THEN 0		-- No Profit? No Commission! No coffee either!
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
WHERE AnnualNumOfSales.YearSold = 2016	-- Test Parameters
	AND SalesPerson.LastName = 'Gilbert'
GROUP BY 
	SalesPerson.LastName,
	SalesPerson.FirstName,
	AnnualNumOfSales.YearSold,	
	AnnualNumOfSales.AnnualNumOfSales;








-----
-- Wrap it in a view for re-use!
IF EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'dbo.vw_SalesPerson_AnnualProfit'))
	DROP VIEW dbo.vw_SalesPerson_AnnualProfit;
GO
CREATE VIEW dbo.vw_SalesPerson_AnnualProfit
AS
SELECT 
	SalesPerson.FirstName,
	SalesPerson.LastName,
	AnnualNumOfSales.YearSold,
	SUM(dbo.udf_CalcNetProfit(vw_AllSoldInventory.VIN)) AS DealerNetProfit,
	-- Byron: Need to wrap the Commission calculation into a new UDF for reuse later
	SUM(CASE
		WHEN dbo.udf_CalcNetProfit(vw_AllSoldInventory.VIN) > 0
		THEN dbo.udf_CalcNetProfit(vw_AllSoldInventory.VIN) * SalesPerson.CommissionRate
		WHEN dbo.udf_CalcNetProfit(vw_AllSoldInventory.VIN) <= 0
		THEN 0		-- No Profit? No Commission! No coffee either!
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
-- Test the Final Report Query!
SELECT 
	FirstName,
	LastName,
	YearSold,
	DealerNetProfit,
	Commission,
	AnnualNumOfSales
FROM dbo.vw_SalesPerson_AnnualProfit
WHERE YearSold = 2016
	AND LastName = 'Gilbert';








-----
-- What's the problem?	
-- Sadie the CFO wants to see ALL the data!
-- Run without parameters
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





