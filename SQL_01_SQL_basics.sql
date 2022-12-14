-- SQL BASICS --
--SELECT, JOIN, GROUP BY, CASE


-- EX01
/* Using the Products and Categories tables, display the product name (Products.ProductName) and the name of the category
(Categories.CategoryName) to which the product belongs. Sort the result by product name (ascending). */

SELECT	P.ProductName,
		C.CategoryName
FROM Products AS P
JOIN Categories AS C ON C.CategoryID = P.CategoryID
ORDER BY P.ProductName ASC;

-- EX02
/* Using the Suppliers table, expand the previous one to also present the name of the supplier of a given product (CompanyName),
name the column SupplierName. Sort the result descending by the unit price of the product. */

SELECT	P.ProductName,
		C.CategoryName,
		S.CompanyName AS SupplierName
FROM Products P
JOIN Categories C ON C.CategoryID = P.CategoryID
JOIN Suppliers S ON S.SupplierID = P.SupplierID
ORDER BY UnitPrice DESC;

-- EX03
/* Using the Products table, display the product names (ProductName) with the highest unit price in a given category (UnitPrice).
Sort the result by product name (ascending). */

WITH MaxPriceInCat (MaxPrice, CategoryID) AS
	(
	SELECT	MAX(P.UnitPrice) AS MaxPrice,
			C.CategoryID 
	FROM Products AS P
	JOIN Categories AS C ON C.CategoryID = P.CategoryID
	GROUP BY C.CategoryID
	)

SELECT	P.ProductName,
		P.UnitPrice
FROM Products AS P
JOIN MaxPriceInCat AS MPIC ON MPIC.MaxPrice = P.UnitPrice
WHERE P.CategoryID = MPIC.CategoryID
ORDER BY ProductName;

-- w/o CTE:
SELECT	P1.ProductName,
		P1.UnitPrice AS MaxPriceInCat
FROM Products P1
WHERE UnitPrice =
			(SELECT MAX(UnitPrice)
			FROM Products P2
			WHERE P1.CategoryID = P2.CategoryID)
ORDER BY P1.ProductName;

-- EX04
/* Using the Products table, display the names of products whose unit price is greater than all average product prices
calculated for other categories (other than the one to which the product belongs). Sort the result by unit price (descending). */

-- AVG price per Category:
SELECT	CategoryID,
		AVG(UnitPrice) AS AveragePrice
FROM Products
GROUP BY CategoryID;

-- 04A:
SELECT	P1.ProductName,
		P1.UnitPrice,
		P1.CategoryID
FROM Products AS P1 
WHERE UnitPrice > ALL(SELECT AVG(P2.UnitPrice)
				   FROM Products AS P2
				   JOIN Categories AS C2 ON P2.CategoryID = C2.CategoryID
				   WHERE P1.CategoryID != P2.CategoryID
				   GROUP BY CategoryName)
ORDER BY P1.UnitPrice DESC;

-- 04BB:
SELECT	P1.ProductName,
		P1.UnitPrice,
		P1.CategoryID
FROM Products P1
WHERE UnitPrice > ALL(SELECT avg(P2.UnitPrice)
					FROM Products P2
					WHERE P1.CategoryID != P2.CategoryID
					GROUP BY P2.CategoryID) 
ORDER BY P1.UnitPrice DESC;


-- EX05
/* Using the Order Details table, extend the previous query to display as well the maximum number of ordered items
(MaxQuantity) of a given product in one order (in a given OrderID). */

with MaxPriceInOrder (ProductID, MaxQuantity) AS
	(
	SELECT	ProductID,
			MAX(quantity) AS MaxQuantity
	FROM [Order Details]
	GROUP BY ProductID
	)

SELECT	P1.ProductName,
		P1.UnitPrice,
		P1.CategoryID,
		MPIO.MaxQuantity
FROM Products P1
JOIN MaxPriceInOrder AS MPIO ON MPIO.ProductID = P1.ProductID
WHERE UnitPrice > ALL(SELECT avg(P2.UnitPrice)
					FROM Products P2
					WHERE P1.CategoryID != P2.CategoryID
					GROUP BY P2.CategoryID) 
ORDER BY P1.ProductName DESC;

-- EX06
/* Using the Products and Order Details tables, display the Category IDs and the sum of all values orders of products
in a given category ([Order Details].UnitPrice * [OrderDetails].Quantity) without discount. The result should contain
only those categories for which the above the sum is greater than 200,000. Sort result by sum of order values ​​(descending)*/

SELECT	P.CategoryID,
		SUM(OD.UnitPrice * OD.Quantity) AS TotalQuantity
FROM [Order Details] AS OD
JOIN Products AS P ON P.ProductID = OD.ProductID
GROUP BY P.CategoryID
HAVING SUM(OD.UnitPrice * OD.Quantity) > 200000

-- EX07
/* Using the Categories table, update the previous query to return except category ID as well as its name.*/

-- 07A:
SELECT	P.CategoryID,
		C.CategoryName,
		SUM(OD.UnitPrice * OD.Quantity) AS TotalQuantity
FROM [Order Details] AS OD
JOIN Products AS P ON P.ProductID = OD.ProductID
JOIN Categories AS C ON C.CategoryID = P.CategoryID
GROUP BY P.CategoryID, C.CategoryName
HAVING SUM(OD.UnitPrice * OD.Quantity) > 200000

-- 07B:
with TotalQuantityPerCategory (CategoryID, TotalQuantity) AS
	(
	SELECT	P.CategoryID,
			SUM(OD.UnitPrice * OD.Quantity) AS TotalQuantity
	FROM [Order Details] AS OD
	JOIN Products AS P ON P.ProductID = OD.ProductID
	GROUP BY P.CategoryID
	HAVING SUM(OD.UnitPrice * OD.Quantity) > 200000
	)

SELECT	C.CategoryID,
		CategoryName,
		TQPC.TotalQuantity
FROM Categories AS C
JOIN TotalQuantityPerCategory AS TQPC
ON C.CategoryID = TQPC.CategoryID

-- EX08
/* Using the Orders and Employees tables, display the number of orders that have been shipped (ShipRegion) to regions other
than those in orders handled by a Robert King employee (FirstName -> Robert; LastName -> King).*/

SELECT *
FROM Employees
WHERE LastName = 'King' and FirstName = 'Robert';

SELECT *
FROM Orders

SELECT DISTINCT ISNULL(O.ShipRegion,'no region') AS ShipReg
FROM Orders AS O
JOIN Employees AS E ON E.EmployeeID = O.EmployeeID
WHERE (LAStName = 'King' and FirstName = 'Robert')

-- 08A
SELECT COUNT(*) AS CNT
FROM Orders
WHERE ShipRegion NOT IN (SELECT DISTINCT ISNULL(O.ShipRegion,'no region') AS ShipReg
						FROM Orders AS O
						JOIN Employees AS E ON E.EmployeeID = O.EmployeeID
						WHERE (LAStName = 'King' and FirstName = 'Robert'))
				OR ShipRegion IS NULL;

-- 08B:
SELECT COUNT(*) AS CNT
FROM Orders O
WHERE NOT EXISTS (SELECT 1 
				FROM Orders P
				JOIN Employees E ON P.EmployeeID = E.EmployeeID
				WHERE P.ShipRegion = O.ShipRegion
				AND E.FirstName = 'Robert' AND E.LAStName = 'King')


-- EX09
/* Using the Orders table, display all shipping countries (ShipCountry) for which they exist
records (orders) that have a filled value in the ShipRegion field as well as records with a null value.*/

SELECT DISTINCT ShipCountry
FROM Orders
WHERE ShipCountry IN (SELECT ShipCountry
						FROM Orders 
						WHERE ShipRegion IS NULL)
				AND ShipRegion IS NOT NULL

-- 09B (FROM labs):
SELECT ShipCountry
FROM Orders
WHERE ShipRegion IS NULL

INTERSECT

SELECT ShipCountry
FROM Orders
WHERE ShipRegion IS NOT NULL

-- EX10
/* Using the appropriate tables, display the product ID (Products.ProductID), product name (Products.ProductName),
supplier Country and city (Suppliers.Country, Suppliers.City - name them accordingly: SupplierCountry and SupplierCity) 
and the Country and city of delivery of the given product (Orders.ShipCountry, Orders.ShipCity).

Limit the score to products that have been shipped at leASt once to the same Country as their supplier.
Additionally, extend the result with information whether, in addition to the Country, the city where the product supplier
is located also matches, with the city to which the product was shipped - name the column FullMatch, which will assume Y/N values.
Sort the result so that the alphabetically sorted products for which there is a full match are displayed first */

SELECT DISTINCT P.ProductID,
				P.ProductName,
				S.Country SupplierCountry,
				S.City SupplierCity,
				O.ShipCountry,
				O.ShipCity,
				
		CASE WHEN O.ShipCity = S.City THEN 'Y'
			ELSE 'N'
			END AS FullMatch

FROM Products AS P
JOIN Suppliers AS S ON S.SupplierID = P.SupplierID
JOIN [Order Details] AS OD ON OD.ProductID = P.ProductID
JOIN Orders AS O ON O.OrderID = OD.OrderID
WHERE S.Country = O.ShipCountry
ORDER BY FullMatch DESC, P.ProductName ASC;

-- EX11
/* Expand the previous query to include the delivery region as well as the shipping region. The FullMatch column should have the following set of values:
	- Y: for full compliance of three values
	- N (the region doesn't match): for matching Country and city, but not region
	- N: for non-compliance
Add also the fields containing the region to the result: Suppliers.Region (name them SupplierRegion) and Orders.ShipRegion) */

SELECT DISTINCT P.ProductID,
				P.ProductName,
				S.Country SupplierCountry,
				S.City SupplierCity,
				S.Region SupplierRegion,
				O.ShipCountry,
				O.ShipCity,
				O.ShipRegion,
		
		CASE WHEN O.ShipCity = S.City and ISNULL(S.Region,0) = ISNULL(O.ShipRegion,0) THEN 'Y'
			WHEN O.ShipCity = S.City and ISNULL(S.Region,0) != ISNULL(O.ShipRegion,0) THEN 'N (the region doesn''t match)'
			ELSE 'N'
			END AS FullMatch

FROM Products AS P
JOIN Suppliers AS S ON S.SupplierID = P.SupplierID
JOIN [Order Details] AS OD ON OD.ProductID = P.ProductID
JOIN Orders AS O ON O.OrderID = OD.OrderID
WHERE S.Country = O.ShipCountry
ORDER BY FullMatch DESC, P.ProductName ASc;

-- EX12
/* Using the Products table, verify that there are two (or more) products with the same name.
The query should return either Yes or No in the DuplicatedProductsFlag column.*/

SELECT DISTINCT

CASE WHEN (SELECT DISTINCT COUNT(*) FROM Products) = (SELECT COUNT(*) FROM Products) THEN 'No'
	ELSE 'Yes'
	END AS DuplicatedProductsFlag 

FROM Products

-- EX13
/* Using the Products and Order Details tables, display the names of the products along with information on how many orders
the given products appeared on. Sort the result so that the products that appear on orders most often appear first. */

SELECT	P.ProductName,
		COUNT(OD.OrderID) AS NumberOfOrders
FROM Products AS P
JOIN [Order Details] AS OD ON OD.ProductID = P.ProductID
GROUP BY P.ProductName
ORDER BY NumberOfOrders DESC;

-- EX14
/* Using the Orders table, expand the previous query so that the above analysis is presented in the context of individual years (Orders.OrderDate)
- name the column OrderYear. -- This time, sort the result so that the most common products are displayed first
-- appearing on orders in the context of a given year, i.e. we are first interested in the year: 1996, THEN 1997, etc. */

SELECT	P.ProductName,
		YEAR(O.OrderDate) AS OrderYear,
		COUNT(OD.OrderID) AS NumberOfOrders
FROM Products AS P
JOIN [Order Details] AS OD ON OD.ProductID = P.ProductID
JOIN Orders AS O ON O.OrderID = OD.OrderID
GROUP BY P.ProductName,
		YEAR(O.OrderDate)
ORDER BY OrderYear ASC, NumberOfOrders DESC;

-- EX15
/* Using the Suppliers table, expand the query to display additionally for each product name of the supplier
of a given product (Suppliers.CompanyName) - name the column SupplierName. */ 

SELECT	P.ProductName,
		S.CompanyName AS SupplierName,
		YEAR(O.OrderDate) AS OrderYear,
		COUNT(OD.OrderID) AS NumberOfOrders
FROM Products AS P
JOIN [Order Details] AS OD ON OD.ProductID = P.ProductID
JOIN Orders AS O ON O.OrderID = OD.OrderID
JOIN Suppliers AS S ON S.SupplierID = P.SupplierID
GROUP BY P.ProductName,
		S.CompanyName,
		YEAR(O.OrderDate)
ORDER BY OrderYear ASC, NumberOfOrders DESC;

