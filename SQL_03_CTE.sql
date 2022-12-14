-- CTE

--Example 00
/* Select products with higher price than the average. */

-- Average product price: 28.8663
SELECT AVG(UnitPrice)
FROM Products

-- no CTE
SELECT P.ProductName, C.CategoryName, P.UnitPrice
FROM Products P
JOIN Categories C ON C.CategoryID = P.CategoryID
WHERE UnitPrice > (SELECT AVG(UnitPrice)
					FROM Products)
ORDER BY P.UnitPrice;

-- With CTE
WITH ProdAvgUnitPrice (AvgUnitPrice) AS
	(
	SELECT AVG(UnitPrice)
	FROM Products
	),

	GreaterThanAvg (ProductName, CategoryID, UnitPrice) AS
	(
	SELECT ProductName, CategoryID, UnitPrice
	FROM Products P
	WHERE UnitPrice > (SELECT AvgUnitPrice
						FROM ProdAvgUnitPrice)
	)

SELECT G.ProductName, C.CategoryName, G.UnitPrice
FROM GreaterThanAvg G
JOIN Categories C ON C.CategoryID = G.CategoryID
ORDER BY P.UnitPrice;


-- EX01
/* Using the Products table, display all product IDs and names (ProductName) whose unit price (UnitPrice) is higher than the average in a given category.
Sort the result by unit price (UnitPrice). Execute the query in two variants: without and with CTE */

-- w/o CTE
SELECT P1.ProductID, P1.ProductName
FROM Products AS P1
WHERE P1.UnitPrice > (SELECT AVG(P2.UnitPrice)
					FROM Products P2
					WHERE P1.CategoryID = P2.CategoryID)
ORDER BY P1.UnitPrice;

-- With CTE
WITH AvgPricePerCat AS
	(SELECT C.CategoryID,
			AVG(P2.UnitPrice) AS AVG
	FROM Products AS P2
	JOIN Categories AS C ON C.CategoryID = P2.CategoryID
	GROUP BY C.CategoryID)

SELECT P1.ProductID, P1.ProductName
FROM Products AS P1
JOIN AvgPricePerCat APPC ON APPC.CategoryID = P1.CategoryID
WHERE P1.UnitPrice > APPC.AVG
ORDER BY P1.UnitPrice;


-- EX02
/* Using the Products and Order Details tables, display all IDs (Products.ProductID) and product names (Products.ProductName)
whose maximum value of orders (UnitPrice*Quantity) is less than the average in the category. 
Sort the result in ascending order by product ID. */

--Order Value Per Category 
SELECT P.CategoryID,
		SUM(OD.UnitPrice * OD.Quantity) Value
FROM [Order Details] OD
JOIN Products P ON P.ProductID = OD.ProductID
GROUP BY OD.OrderID, P.CategoryID;

--Order Value Per Product 
SELECT P.ProductID,
		SUM(OD.UnitPrice * OD.Quantity) Value
FROM [Order Details] OD
JOIN Products P ON P.ProductID = OD.ProductID
GROUP BY OD.OrderID, P.ProductID
ORDER BY P.ProductID;

--Max Order Value Per Product
WITH OrderValuePerProd (ProductID, ProdOrderValue) AS
	(
	SELECT	P.ProductID,
			SUM(OD.UnitPrice * OD.Quantity) ProdOrderValue
	FROM [Order Details] OD
	JOIN Products P ON P.ProductID = OD.ProductID
	GROUP BY OD.OrderID, P.ProductID
	)
	
	SELECT	P.CategoryID,
			P.ProductID,
			P.ProductName,
			ROUND(MAX(OVPP.ProdOrderValue),2) AS MaxOrderValue
	FROM Products P
	JOIN OrderValuePerProd OVPP ON OVPP.ProductID = P.ProductID
	GROUP BY P.CategoryID, P.ProductID, P.ProductName
	ORDER BY P.CategoryID, P.ProductID

--Average Order Value Per Category
WITH OrderValuePerCat (CategoryID, CatOrderValue) AS
	(
	SELECT	P.CategoryID,
			SUM(OD.UnitPrice * OD.Quantity) AS CatOrderValue
	FROM [Order Details] OD
	JOIN Products P ON P.ProductID = OD.ProductID
	GROUP BY OD.OrderID, P.CategoryID
	)
	
	SELECT	P.CategoryID,
			ROUND(AVG(OVPC.CatOrderValue),2) AS AvgOrderValue
	FROM Products P
	JOIN OrderValuePerCat OVPC ON OVPC.CategoryID = P.CategoryID
	GROUP BY P.CategoryID
	ORDER BY P.CategoryID

--Combine all those queries: look for MAX order value (grouped by products) lower than AVG order value (grouped by categories)
WITH OrderValuePerProd (ProductID, ProdOrderValue) AS
	(
	SELECT	P.ProductID,
			SUM(OD.UnitPrice * OD.Quantity) AS ProdOrderValue
	FROM [Order Details] OD
	JOIN Products P ON P.ProductID = OD.ProductID
	GROUP BY OD.OrderID, P.ProductID
	),

	OrderValuePerCat (CategoryID, CatOrderValue) AS
	(
	SELECT	P.CategoryID,
			SUM(OD.UnitPrice * OD.Quantity) AS CatOrderValue
	FROM [Order Details] OD
	JOIN Products P ON P.ProductID = OD.ProductID
	GROUP BY OD.OrderID, P.CategoryID
	),
	
	AverageOrderValuePerCat (CategoryID, AvgOrderValue) AS
	(
	SELECT	P.CategoryID,
			ROUND(AVG(OVPC.CatOrderValue),2) AS AvgOrderValue
	FROM Products P
	JOIN OrderValuePerCat OVPC ON OVPC.CategoryID = P.CategoryID
	GROUP BY P.CategoryID
	),

	MaxOrderValuePerProduct (CategoryID, ProductID, ProductName, MaxOrderValue) AS
	(
	SELECT	P.CategoryID,
			P.ProductID,
			P.ProductName,
			MAX(OVPP.ProdOrderValue) AS MaxOrderValue
	FROM Products P
	JOIN OrderValuePerProd OVPP ON OVPP.ProductID = P.ProductID
	GROUP BY P.CategoryID, P.ProductID, P.ProductName
	)
	
SELECT	MOVPP.CategoryID,
		MOVPP.ProductID,
		MOVPP.ProductName,
		MOVPP.MaxOrderValue,
		AOVPC.AvgOrderValue
FROM MaxOrderValuePerProduct MOVPP
JOIN AverageOrderValuePerCat AOVPC ON AOVPC.CategoryID = MOVPP.CategoryID
WHERE MOVPP.MaxOrderValue < AOVPC.AvgOrderValue
ORDER BY MOVPP.ProductID


-- EX03
/*Using the Employees table, display the ID, name and surname of the employee together with an identifier, name and surname of his supervisor.
To find a given supervisor use the ReportsTo field. Display results for hierarchy level no greater than 1 (starting from 0).
Add the WhoIsThis column to the result, which will take the appropriate values for of a given level:
	- Level = 0 – Krzysiu Jarzyna ze Szczecina
	- Level = 1 - Mr. Frog*/


WITH EmployeesCTE
	(
	EmployeeID, FirstName, LastName, ReportsTo, ManagerFirstName, ManagerLastName, Level
	)
	AS
	(
	SELECT	EmployeeID,
			FirstName,
			LastName,
			ReportsTo,
			CAST(null AS nvarchar(10)) AS ManagerFirstName, 
			CAST(null AS nvarchar(20)) AS ManagerLastName,
			0 AS Level
	FROM Employees
	WHERE ReportsTo is null
	
	UNION all 
	
		SELECT
			E.EmployeeID,
			E.FirstName,
			E.LastName,
			R.EmployeeID,
			R.FirstName,
			R.LastName,
			Level + 1
	FROM Employees E
	JOIN EmployeesCTE R ON E.ReportsTo = R.EmployeeID
	WHERE Level < 1
	)
SELECT	EmployeeID,
		FirstName,
		LastName,
		ReportsTo,
		ManagerFirstName, 
		ManagerLastName,
		CASE Level
			WHEN 0 THEN 'Krzysiu Jarzyna ze Szczecina'
			WHEN 1 THEN 'Mr. Frog'
		END AS Level
FROM EmployeesCTE;


-- EX04
/* Extend the previous query so that in the ReportsTo column, instead of the identifier, it shows the value
from the supervisor's WhoIsThis column. This time present all levels of the hierarchy. Let the WhoIsThis column for the Level=2
take the value "Rezyser Kina Akcji". */

WITH EmployeesCTE (EmployeeID, FirstName, LastName, ReportsTo, ManagerFirstName, ManagerLastName, Level) AS
	(
	SELECT	EmployeeID,
			FirstName,
			LastName,
			ReportsTo,
			CAST(null AS nvarchar(10)) AS ManagerFirstName, 
			CAST(null AS nvarchar(20)) AS ManagerLastName,
			0 AS Level
	FROM Employees
	WHERE ReportsTo is null
	
	UNION all 
	
		SELECT
			E.EmployeeID,
			E.FirstName,
			E.LastName,
			R.EmployeeID,
			R.FirstName,
			R.LastName,
			Level + 1
	FROM Employees E
	JOIN EmployeesCTE R ON E.ReportsTo = R.EmployeeID
	)
SELECT	EmployeeID,
		FirstName,
		LastName,
		ReportsTo,
		ManagerFirstName, 
		ManagerLastName,
		CASE Level
			WHEN 0 THEN 'Krzysiu Jarzyna ze Szczecina'
			WHEN 1 THEN 'Mr. Frog'
			WHEN 2 THEN 'Rezyser Kina Akcji'
		END AS Level
FROM EmployeesCTE;


--EX05
/*Zadanie 5.
Using CTEs and recursions, build a query to represent the Fibonacci sequence.*/

WITH fib (N, FibValue, NextValue) AS
	(
	SELECT	0 AS N,
			0 AS FibValue,
			1 AS NextValue
	
	UNION all 
	
	SELECT	N+1,
			NextValue,
			FibValue + NextValue
	FROM fib
	WHERE N <10
	)

SELECT N, FibValue
FROM fib