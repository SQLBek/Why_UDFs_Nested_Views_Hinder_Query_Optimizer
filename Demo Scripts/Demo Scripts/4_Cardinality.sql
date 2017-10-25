-----
-- Nested Level: Cardinality Demo
USE AutoDealershipDemo;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
DBCC FREEPROCCACHE;
GO








-----
-- Expand this view: Cardinality.InventorySalesHistory_All
EXEC sp_helpExpandView @ViewName = 'Cardinality.InventorySalesHistory_All',
	@OutputFormat = 'Horizontal',
	@ShowObjectCount = 1;








-----
-- Turn on Actual Execution Plan
DBCC FREEPROCCACHE;
GO
SELECT *
FROM Cardinality.InventorySalesHistory_All
WHERE PackageName = 'Extra Luxury Edition'
GO




-----
-- Record Parse & Compile Time:
--   XXXX
-- Record Elapsed Time:
--   XXXX
-- Approx Logical Reads:
--   XXXX
--
-----
-- Exec Plan: Open Properties
-- estimated row count
-- estimated subtree cost
-- optimization level





-----
-- Focused specific query
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
GO




-----
-- Messages: re-compare timings
--
-----
-- Open Properties
-- estimated row count
-- estimated subtree cost
-- optimization level

-- OPTIONAL: 
-- Turn off Exec Plan & re-run above with workload script