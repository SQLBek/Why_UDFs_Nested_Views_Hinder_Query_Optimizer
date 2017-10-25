USE AutoDealershipDemo;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
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
-- Look at definition of dbo.vw_SalesPerson_AnnualProfit_NoUDF
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
	AnnualNumOfSales.AnnualNumOfSales;
GO








-----
-- Four views being referenced in this view
-- dbo.vw_SalesPerson_AnnualNumOfSales
-- dbo.vw_AllSoldInventory
-- dbo.BaseVw_SalesHistory
-- dbo.BaseVw_SalesPerson








-----
-- What's inside dbo.vw_SalesPerson_AnnualNumOfSales
-- We saw this earlier. It references another view
-- dbo.vw_SalesPerson_SalesPerMonth
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
-- What's inside dbo.vw_SalesPerson_SalesPerMonth
IF EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'dbo.vw_SalesPerson_SalesPerMonth'))
	DROP VIEW dbo.vw_SalesPerson_SalesPerMonth;
GO
CREATE VIEW dbo.vw_SalesPerson_SalesPerMonth
AS  
SELECT   
	SalesPerson.FirstName,
	SalesPerson.LastName,
	CAST(  
		CAST(YEAR(SalesHistory.TransactionDate) AS VARCHAR(4)) + '-'  
		+ CAST(MONTH(SalesHistory.TransactionDate) AS VARCHAR(2)) + '-01'  
		AS DATE  
	) AS MonthYearSold,
	COUNT(1) AS NumOfSales,
	SUM(SellPrice) AS TotalSellPrice,
	MIN(SellPrice) AS MinSellPrice,
	MAX(SellPrice) AS MaxSellPrice,
	AVG(SellPrice) AS AvgSellPrice,
	SalesPerson.SalesPersonID  
FROM dbo.BaseVw_SalesPerson AS SalesPerson
INNER JOIN dbo.BaseVw_SalesHistory AS SalesHistory
	ON SalesHistory.SalesPersonID = SalesPerson.SalesPersonID  
GROUP BY   
	SalesPerson.SalesPersonID,
	SalesPerson.FirstName,
	SalesPerson.LastName,
	CAST(  
		CAST(YEAR(SalesHistory.TransactionDate) AS VARCHAR(4)) + '-'  
		+ CAST(MONTH(SalesHistory.TransactionDate) AS VARCHAR(2)) + '-01'  
		AS DATE  
	);
GO








-----
-- What's inside dbo.vw_AllSoldInventory?
IF EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'dbo.vw_AllSoldInventory'))
	DROP VIEW dbo.vw_AllSoldInventory;
GO
CREATE VIEW dbo.vw_AllSoldInventory
AS  
SELECT   
	Inventory.VIN,
	VehicleBaseModel.MakeName,
	VehicleBaseModel.ModelName,
	VehicleBaseModel.ColorName,
	Package.PackageName,
	Inventory.InvoicePrice,
	Inventory.MSRP,
	SalesHistory.SellPrice,
	Inventory.DateReceived,
	SalesHistory.TransactionDate,
	Inventory.InventoryID,
	SalesHistory.SalesHistoryID
FROM dbo.BaseVW_Inventory AS Inventory  
INNER JOIN dbo.vw_VehicleBaseModel AS VehicleBaseModel  
	ON Inventory.BaseModelID = VehicleBaseModel.BaseModelID    
INNER JOIN dbo.vw_VehiclePackageDetail AS Package  
	ON Inventory.PackageID = Package.PackageID    
INNER JOIN dbo.BaseVW_SalesHistory AS SalesHistory  
	ON SalesHistory.InventoryID = Inventory.InventoryID;
GO








-----
-- What's inside dbo.Vw_VehiclePackageDetail?
IF EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'dbo.Vw_VehiclePackageDetail'))
	DROP VIEW dbo.Vw_VehiclePackageDetail;
GO
CREATE VIEW dbo.Vw_VehiclePackageDetail  
AS  
SELECT DISTINCT  
	BaseVw_Inventory.BaseModelID,
	BaseVw_Inventory.PackageID,
	Vw_VehicleBaseModel.MakeName,
	Vw_VehicleBaseModel.ModelName,
	Vw_VehicleBaseModel.ColorName,
	Vw_VehicleBaseModel.ColorCode,
	BaseVw_Package.PackageName,
	BaseVw_Package.PackageCode,
	BaseVw_Package.Description,
	BaseVw_Package.TrueCost,
	BaseVw_Package.InvoicePrice,
	BaseVw_Package.MSRP
FROM dbo.BaseVw_Inventory  
INNER JOIN dbo.Vw_VehicleBaseModel  
	ON BaseVw_Inventory.BaseModelID = Vw_VehicleBaseModel.BaseModelID  
INNER JOIN dbo.BaseVw_Package  
	ON BaseVw_Inventory.PackageID = BaseVw_Package.PackageID;  
GO








-----
-- What's inside dbo.Vw_VehicleBaseModel?
IF EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'dbo.Vw_VehicleBaseModel'))
	DROP VIEW dbo.Vw_VehicleBaseModel;
GO
CREATE VIEW dbo.Vw_VehicleBaseModel  
AS  
SELECT   
	BaseVw_BaseModel.BaseModelID,  
	BaseVw_Make.MakeName,  
	BaseVw_Model.ModelName,  
	BaseVw_Color.ColorName,  
	BaseVw_Color.ColorCode  
FROM dbo.BaseVw_BaseModel  
INNER JOIN dbo.BaseVw_Make  
	ON BaseVw_BaseModel.MakeID = BaseVw_Make.MakeID  
INNER JOIN dbo.BaseVw_Model  
	ON BaseVw_BaseModel.ModelID = BaseVw_Model.ModelID  
INNER JOIN dbo.BaseVw_Color  
	ON BaseVw_BaseModel.ColorID = BaseVw_Color.ColorID;  
GO
  








-----
-- Why does this matter?  
-- Views get expanded
-- Show Est Exec Plan.  
SELECT 
	FirstName,
	LastName,
	YearSold,
	DealerNetProfit,
	Commission,
	AnnualNumOfSales
FROM dbo.vw_SalesPerson_AnnualProfit_NoUDF
WHERE YearSold = 2016
	AND LastName = 'Gilbert';
GO  








-----
-- This is what this query really looks like 
-- How many SELECT statements are buried in here?
SELECT 
	FirstName,
	LastName,
	YearSold,
	DealerNetProfit,
	Commission,
	AnnualNumOfSales
FROM (
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
	FROM (
		SELECT   
			Inventory.VIN,
			VehicleBaseModel.MakeName,
			VehicleBaseModel.ModelName,
			VehicleBaseModel.ColorName,
			Package.PackageName,
			Inventory.InvoicePrice,
			Inventory.MSRP,
			SalesHistory.SellPrice,
			Inventory.DateReceived,
			SalesHistory.TransactionDate,
			Inventory.InventoryID,
			SalesHistory.SalesHistoryID
		FROM (
			SELECT 
				InventoryID,
				VIN,
				BaseModelID,
				PackageID,
				TrueCost,
				InvoicePrice,
				MSRP,
				DateReceived
			FROM dbo.Inventory
		-- ) AS dbo.BaseVW_Inventory 
		) AS Inventory  
		INNER JOIN (
			SELECT     
				BaseVw_BaseModel.BaseModelID,    
				BaseVw_Make.MakeName,    
				BaseVw_Model.ModelName,    
				BaseVw_Color.ColorName,    
				BaseVw_Color.ColorCode    
			FROM (
				SELECT 
					BaseModel.BaseModelID,  
					BaseModel.MakeID,  
					BaseModel.ModelID,  
					BaseModel.ColorID,  
					BaseModel.TrueCost,  
					BaseModel.InvoicePrice,  
					BaseModel.MSRP  
				FROM Vehicle.BaseModel 
			) AS BaseVw_BaseModel    
			INNER JOIN (
				SELECT 
					Make.MakeID,  
					Make.MakeName  
				FROM Vehicle.Make
			) AS BaseVw_Make 
				ON BaseVw_BaseModel.MakeID = BaseVw_Make.MakeID    
			INNER JOIN (
				SELECT 
					Model.ModelID,  
					Model.ModelName,  
					Model.ClassificationID  
				FROM Vehicle.Model
			) AS BaseVw_Model    
				ON BaseVw_BaseModel.ModelID = BaseVw_Model.ModelID    
			INNER JOIN (
				SELECT 
					Color.ColorID,  
					Color.ColorName,  
					Color.ColorCode  
				FROM Vehicle.Color
			) AS BaseVw_Color    
				ON BaseVw_BaseModel.ColorID = BaseVw_Color.ColorID  
		--) AS dbo.vw_VehicleBaseModel 
		) AS VehicleBaseModel  
			ON Inventory.BaseModelID = VehicleBaseModel.BaseModelID    
		INNER JOIN (
			SELECT DISTINCT  
				BaseVw_Inventory.BaseModelID,
				BaseVw_Inventory.PackageID,
				Vw_VehicleBaseModel.MakeName,
				Vw_VehicleBaseModel.ModelName,
				Vw_VehicleBaseModel.ColorName,
				Vw_VehicleBaseModel.ColorCode,
				BaseVw_Package.PackageName,
				BaseVw_Package.PackageCode,
				BaseVw_Package.Description,
				BaseVw_Package.TrueCost,
				BaseVw_Package.InvoicePrice,
				BaseVw_Package.MSRP
			FROM (
				SELECT 
					InventoryID,
					VIN,
					BaseModelID,
					PackageID,
					TrueCost,
					InvoicePrice,
					MSRP,
					DateReceived
				FROM dbo.Inventory
			) AS BaseVw_Inventory  
			INNER JOIN (
				SELECT     
					BaseVw_BaseModel.BaseModelID,    
					BaseVw_Make.MakeName,    
					BaseVw_Model.ModelName,    
					BaseVw_Color.ColorName,    
					BaseVw_Color.ColorCode    
				FROM (
					SELECT 
						BaseModel.BaseModelID,  
						BaseModel.MakeID,  
						BaseModel.ModelID,  
						BaseModel.ColorID,  
						BaseModel.TrueCost,  
						BaseModel.InvoicePrice,  
						BaseModel.MSRP  
					FROM Vehicle.BaseModel 
				) AS BaseVw_BaseModel    
				INNER JOIN (
					SELECT 
						Make.MakeID,  
						Make.MakeName  
					FROM Vehicle.Make
				) AS BaseVw_Make 
					ON BaseVw_BaseModel.MakeID = BaseVw_Make.MakeID    
				INNER JOIN (
					SELECT 
						Model.ModelID,  
						Model.ModelName,  
						Model.ClassificationID  
					FROM Vehicle.Model
				) AS BaseVw_Model    
					ON BaseVw_BaseModel.ModelID = BaseVw_Model.ModelID    
				INNER JOIN (
					SELECT 
						Color.ColorID,  
						Color.ColorName,  
						Color.ColorCode  
					FROM Vehicle.Color
				) AS BaseVw_Color    
					ON BaseVw_BaseModel.ColorID = BaseVw_Color.ColorID  
			) AS Vw_VehicleBaseModel  
				ON BaseVw_Inventory.BaseModelID = Vw_VehicleBaseModel.BaseModelID  
			INNER JOIN (
				SELECT 
					Package.PackageID,  
					Package.PackageName,  
					Package.PackageCode,  
					Package.Description,  
					Package.TrueCost,  
					Package.InvoicePrice,  
					Package.MSRP  
				FROM Vehicle.Package
			) AS BaseVw_Package  
				ON BaseVw_Inventory.PackageID = BaseVw_Package.PackageID
		--) AS dbo.vw_VehiclePackageDetail 
		) AS Package  
			ON Inventory.PackageID = Package.PackageID    
		INNER JOIN (
			SELECT 
				SalesHistory.SalesHistoryID,  
				SalesHistory.CustomerID,  
				SalesHistory.SalesPersonID,  
				SalesHistory.InventoryID,  
				SalesHistory.TransactionDate,  
				SalesHistory.SellPrice  
			FROM dbo.SalesHistory  
		--) AS dbo.BaseVW_SalesHistory 
		) AS SalesHistory  
			ON SalesHistory.InventoryID = Inventory.InventoryID
	) AS vw_AllSoldInventory
	INNER JOIN (
		SELECT 
			SalesHistory.SalesHistoryID,  
			SalesHistory.CustomerID,  
			SalesHistory.SalesPersonID,  
			SalesHistory.InventoryID,  
			SalesHistory.TransactionDate,  
			SalesHistory.SellPrice  
		FROM dbo.SalesHistory
	--) AS dbo.BaseVw_SalesHistory 
	) AS SalesHistory
		ON vw_AllSoldInventory.SalesHistoryID = SalesHistory.SalesHistoryID
	INNER JOIN (
		SELECT 
			SalesPerson.SalesPersonID,  
			SalesPerson.FirstName,  
			SalesPerson.LastName,  
			SalesPerson.Email,  
			SalesPerson.PhoneNumber,  
			SalesPerson.DateOfHire,  
			SalesPerson.Salary,  
			SalesPerson.CommissionRate  
		FROM dbo.SalesPerson 
	--) AS BaseVw_SalesPerson 
	) AS SalesPerson
		ON SalesHistory.SalesPersonID = SalesPerson.SalesPersonID
	INNER JOIN (
		SELECT 
			vw_SalesPerson_SalesPerMonth.FirstName,
			vw_SalesPerson_SalesPerMonth.LastName,
			YEAR(vw_SalesPerson_SalesPerMonth.MonthYearSold) AS YearSold,
			SUM(NumOfSales) AS AnnualNumOfSales,
			vw_SalesPerson_SalesPerMonth.SalesPersonID
		FROM (
		SELECT   
			SalesPerson.FirstName,
			SalesPerson.LastName,
			CAST(  
				CAST(YEAR(SalesHistory.TransactionDate) AS VARCHAR(4)) + '-'  
				+ CAST(MONTH(SalesHistory.TransactionDate) AS VARCHAR(2)) + '-01'  
				AS DATE  
			) AS MonthYearSold,
			COUNT(1) AS NumOfSales,
			SUM(SellPrice) AS TotalSellPrice,
			MIN(SellPrice) AS MinSellPrice,
			MAX(SellPrice) AS MaxSellPrice,
			AVG(SellPrice) AS AvgSellPrice,
			SalesPerson.SalesPersonID  
		FROM (
			SELECT 
				SalesPerson.SalesPersonID,  
				SalesPerson.FirstName,  
				SalesPerson.LastName,  
				SalesPerson.Email,  
				SalesPerson.PhoneNumber,  
				SalesPerson.DateOfHire,  
				SalesPerson.Salary,  
				SalesPerson.CommissionRate  
			FROM dbo.SalesPerson
		--) AS dbo.BaseVw_SalesPerson 
		) AS SalesPerson
		INNER JOIN (
			SELECT 
				SalesHistory.SalesHistoryID,  
				SalesHistory.CustomerID,  
				SalesHistory.SalesPersonID,  
				SalesHistory.InventoryID,  
				SalesHistory.TransactionDate,  
				SalesHistory.SellPrice  
			FROM dbo.SalesHistory 
		--) AS dbo.BaseVw_SalesHistory 
		) AS SalesHistory
			ON SalesHistory.SalesPersonID = SalesPerson.SalesPersonID  
		GROUP BY   
			SalesPerson.SalesPersonID,
			SalesPerson.FirstName,
			SalesPerson.LastName,
			CAST(  
				CAST(YEAR(SalesHistory.TransactionDate) AS VARCHAR(4)) + '-'  
				+ CAST(MONTH(SalesHistory.TransactionDate) AS VARCHAR(2)) + '-01'  
				AS DATE  
			)
		) AS vw_SalesPerson_SalesPerMonth
		GROUP BY
			vw_SalesPerson_SalesPerMonth.SalesPersonID,
			vw_SalesPerson_SalesPerMonth.FirstName,
			vw_SalesPerson_SalesPerMonth.LastName,
			YEAR(vw_SalesPerson_SalesPerMonth.MonthYearSold)
	
	--) AS dbo.vw_SalesPerson_AnnualNumOfSales 
	) AS AnnualNumOfSales
		ON SalesPerson.SalesPersonID = AnnualNumOfSales.SalespersonID
		AND YEAR(vw_AllSoldInventory.TransactionDate) = AnnualNumOfSales.YearSold
	GROUP BY 
		SalesPerson.LastName,
		SalesPerson.FirstName,
		AnnualNumOfSales.YearSold,	
		AnnualNumOfSales.AnnualNumOfSales
)
AS vw_SalesPerson_AnnualProfit_NoUDF
WHERE YearSold = 2016
	AND LastName = 'Gilbert';
GO

-- TWENTY FOUR!!!  24!!!








-----
-- Unravelling this is a pain!
-- How about using a free script tool instead?
EXEC dbo.sp_helpExpandView
	@ViewName = N'dbo.vw_SalesPerson_AnnualProfit_NoUDF',
	@OutputFormat = 'Horizontal';








-----
-- Can break this down from a different angle too
EXEC dbo.sp_helpExpandView
	@ViewName = N'dbo.vw_SalesPerson_AnnualProfit_NoUDF',
	@OutputFormat = 'Vertical';








-----
-- Can show # of times an object is referenced too!
-- Limitation - Cannot count multiple occurances of an 
-- object, on the same hierarchy level.
EXEC dbo.sp_helpExpandView
	@ViewName = N'dbo.vw_SalesPerson_AnnualProfit_NoUDF',
	@OutputFormat = 'Vertical',
	@ShowObjectCount = 1;








-----
-- Why do we care?  
-- Cardinality & the Query Optimizer