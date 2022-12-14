--AGGREGATION AND GROUPING

-- EX01
/* Using the Products table, display the maximum unit price of the available products (UnitPrice). */
SELECT MAX(UnitPrice) AS MaxUnitPrice
FROM Products


-- EX02
/* Using the Products and Categories tables, display the sum of the product values ​​in the warehouse (UnitPrice * UnitsInStock) divided into categories.
Sort the result by category (ascending). */
SELECT TOP 5*
FROM Products

SELECT	C.CategoryName,
		SUM(P.UnitPrice * P.UnitsInStock) AS StockValue
FROM Products AS P
JOIN Categories AS C ON C.CategoryID = P.CategoryID
GROUP BY C.CategoryName
ORDER BY C.CategoryName ASC;


-- EX03
/* Extend the query from EX02 so that only the categories for which are presented the value of products exceeds 10000.
Sort the result descending by product value. */

SELECT	C.CategoryName,
		SUM(P.UnitPrice * P.UnitsInStock) AS StockValue
FROM Products AS P
JOIN Categories AS C ON C.CategoryID = P.CategoryID
GROUP BY C.CategoryName
HAVING SUM(P.UnitPrice * P.UnitsInStock) > 10000
ORDER BY C.CategoryName ASC;

-- EX04
/* Using the Suppliers, Products and Order Details tables, display information on how many unique orders appeared products
of a given supplier. Sort the results alphabetically by name suppliers. */

SELECT TOP 5*
FROM Products

SELECT TOP 5*
FROM Suppliers

SELECT TOP 5*
FROM [Order Details]

SELECT	S.CompanyName,
		COUNT(DISTINCT OD.OrderID) AS NumberOfOrders
FROM Suppliers AS S
JOIN Products AS P ON P.SupplierID = S.SupplierID
JOIN [Order Details] AS OD ON OD.ProductID = P.ProductID
GROUP BY CompanyName
ORDER BY CompanyName;

-- EX05
/* Using the Orders, Customers, and Order Details tables, show the average, minimum, and the maximum value of the order for each customer
(Customers.CustomerID). Sort the results according to the average value orders - descending. Remember to keep the average, minimum and maximum
order value calculated based on its value, i.e. the sum of the products of unit prices and the size of the order. */

--!!!WRONG SOLUTION!!!
SELECT O.CustomerID, 
		AVG(OD.UnitPrice * OD.Quantity) AverageOrder,
		MIN(OD.UnitPrice * OD.Quantity) MinOrder,
		MAX(OD.UnitPrice * OD.Quantity) MaxOrder
FROM [Order Details] AS OD
JOIN Orders AS O ON O.OrderID = OD.OrderID
GROUP BY O.CustomerID
ORDER BY AVG(OD.UnitPrice * OD.Quantity);

--Correct:
with OrderSumPerID (OrderID, OrderSum) AS
	(
	SELECT	OD.OrderID,
			SUM(OD.UnitPrice * OD.Quantity) AS OrderSum
	FROM [Order Details] OD
	JOIN Orders O ON O.OrderID = OD.OrderID
	GROUP BY OD.OrderID
	)

SELECT	O.CustomerID,
		AVG(OrderSum) AS AverageOrder,
		MIN(OrderSum) AS MinOrder,
		MAX(OrderSum) AS MaxOrder
FROM OrderSumPerID AS OSPI
JOIN Orders AS O ON O.OrderID = OSPI.OrderID
GROUP BY O.CustomerID
ORDER BY AVG(OrderSum) DESC;

-- EX06
/* Using the Orders table, display the dates (OrderDate) where there was more than one order taking into account the exact number of orders. 
Display the order date in the format YYYY-MM-DD. Result sort descending by number of orders. */
SELECT *
FROM Orders

SELECT	CAST(OrderDate AS date) AS OrderDate,
		COUNT(DISTINCT OrderID) AS CNT
FROM Orders
GROUP BY OrderDate
HAVING COUNT(DISTINCT OrderID) > 1
ORDER BY CNT DESC;

-- EX07
/* Using the Orders table, analyze the number of orders in 3 dimensions: Year and month, year and overall summary.
Sort the result by "Year-Month" (descending). */

SELECT	DATEPART(YEAR, OrderDate) 'Year',
		DATEPART(mm, OrderDate) 'Month'
FROM Orders

--07A:
SELECT	FORMAT(OrderDate, 'yyyy') 'Year',
		FORMAT(OrderDate, 'yyyy-MM') 'Year-Month',
		COUNT(DISTINCT OrderID) CNT
FROM Orders
GROUP BY ROLLUP	(FORMAT(OrderDate, 'yyyy'),
				FORMAT(OrderDate, 'yyyy-MM'))
ORDER BY 'Year-Month' DESC, 'Year' DESC;

--07B (less clear to read data)
SELECT	DATEPART(YEAR, OrderDate) AS 'Year',
		DATEPART(mm, OrderDate) AS 'Month',
		COUNT(DISTINCT OrderID) AS CNT
FROM Orders
GROUP BY ROLLUP (DATEPART(YEAR, OrderDate),
				DATEPART(mm, OrderDate))
ORDER BY 'Year' DESC;


-- EX08
/* Using the Orders table, analyze the number of orders in following dimensions:
	- Country, region and city of delivery
	- Country and region of delivery
	- Country of delivery
	- Summary
Add a GroupingLevel column to explain the grouping level that's for each dimension will assume the following values:
	- Country & Region & City
	- Country & Region
	- Country
	- Total
The region field may have empty values - mark such values as "Not Provided".
Sort the result alphabetically according to the country of delivery. */

SELECT	ShipCountry,
		
		CASE 
			WHEN GROUPING (ShipRegion) = 0 AND ShipRegion IS NULL THEN 'Not provided'
			ELSE ShipRegion
		END ShipRegion,
		ShipCity,
		COUNT(1) AS CNT,
		
		CASE GROUPING_ID (ShipCountry,ShipRegion,ShipCity)
			WHEN 0 THEN 'Country & Region & City'
			WHEN 1 THEN 'Country & Region'
			WHEN 3 THEN 'Country'
			WHEN 7 THEN 'Total'
		END AS GroupingLevel
FROM orders
GROUP BY ROLLUP (ShipCountry,ShipRegion,ShipCity)
ORDER BY ShipCountry

-- EX09
/* Using the tables Orders, Order Details and Customers, present a full analysis of the sum of the value of orders
in following dimensions:
	- Year (Order.OrderDate)
	- Customer (Customers.CompanyName)
	- Overall summary
Include only records that have all the required information (no external joins needed).
Sort the result by customer name (alphabetically). */

SELECT	FORMAT(O.OrderDate, 'yyyy') AS 'Year',
		C.CompanyName,
		SUM(OD.Quantity * OD.UnitPrice) AS OrdersValue
FROM Orders O 
JOIN Customers C ON C.CustomerID = O.CustomerID
JOIN [Order Details] OD ON OD.OrderID = O.OrderID

GROUP BY CUBE (FORMAT(O.OrderDate, 'yyyy'),
				C.CompanyName)
ORDER BY C.CompanyName;


-- EX10
/* Modify the previous query to include the country instead of the name (Customers.Country) and region (Customers.Region)
of the customer (the dimension should consist of two: country and region; summary should not be counted separately
for country and region). Sort the results by country name (alphabetically).*/

SELECT	FORMAT(O.OrderDate, 'yyyy') AS 'Year',
		C.Country AS Country,
		C.Region AS Region,
		SUM(OD.Quantity * OD.UnitPrice) AS OrdersValue
FROM Orders O 
JOIN Customers C ON C.CustomerID = O.CustomerID
JOIN [Order Details] OD ON OD.OrderID = O.OrderID

GROUP BY CUBE (FORMAT(O.OrderDate, 'yyyy'),
				(C.Country,
				C.Region))
ORDER BY C.Country;

-- EX11
/* Use the Orders, Orders Details, Customers, Products, Suppliers, and Categories tables to represent
analysis of the total value of orders (without discounts) for specific dimensions:
	- Categories (Cateogires.CategoryName)
	- Supplier country (Suppliers.Country)
	- Customer country and region (Customers.Country, Customers.Region)
Dimensions consisting of more than one attribute should be treated as a whole (no groupings for subsets).
Don't generate additional summaries - include them carefully in dimensions listed above.
Add a GroupingLevel field to the result explaining the level of grouping that will take the values
respectively for individual dimensions:
	- Category
	- Country-Supplier
	- Country & Region - Customer
Sort the result alphabetically first by GroupingLevel column (ascending) and then
after the column with the sum of the order values OrdersValue (descending). */


SELECT Cat.CategoryName,
       S.Country,
       C.Country,
       C.Region,
       SUM(OD.Quantity * OD.UnitPrice) AS OrdersValue,
       CASE GROUPING_id(Cat.CategoryName,
                        S.Country,
                        C.Country,
                        C.Region)
           WHEN 7 THEN 'Category'
           WHEN 11 THEN 'Country - Supplier'
           WHEN 12 THEN 'Country & Region - Customer'
           END AS GroupingLevel
FROM Orders O
         JOIN [Order Details] OD ON O.OrderID = OD.OrderID
         JOIN Customers C ON O.CustomerID = C.CustomerID
         JOIN Products P ON OD.ProductID = P.ProductID
         JOIN Categories Cat ON P.CategoryID = Cat.CategoryID
         JOIN Suppliers S ON P.SupplierID = S.SupplierID
GROUP BY GROUPING SETS ((Cat.CategoryName), (S.Country), (C.Country, C.Region))
ORDER BY GroupingLevel, SUM(OD.Quantity * OD.UnitPrice) DESC;

-- EX12
/* Using the Orders and Shippers tables, present a table containing the number of completed orders
to a given country (ShipCountry) by a given transport company. Enter the country of delivery as the rows a
as supplier columns. Sort the result by the name of the country of delivery (alphabetically). */

SELECT * FROM Shippers

-- Query to produce the data
SELECT	O.ShipCountry AS Country,
		S.CompanyName AS Company,
		COUNT(DISTINCT O.OrderID) CNT
FROM Orders O
JOIN Shippers S ON S.ShipperID = O.ShipVia
GROUP BY O.ShipCountry, S.CompanyName

-- Pivot query:
SELECT	[Country], [Speedy Express], [United Package], [Federal Shipping]
FROM
	(SELECT	O.ShipCountry AS Country,
			S.CompanyName AS Company,
			COUNT(DISTINCT O.OrderID) CNT
	FROM Orders O
	JOIN Shippers S ON S.ShipperID = O.ShipVia
	GROUP BY O.ShipCountry, S.CompanyName
	) Query
PIVOT
(
SUM(Query.CNT)
FOR Company IN ([Speedy Express], [United Package], [Federal Shipping])
) AS CNT

-- EX13
/*Including the Order Details table, update the previous query so that instead of a number
completed orders, the sum of the value of orders handled by a given company appeared
freight forwarded to your country.*/

--Query to produce the data
SELECT	O.ShipCountry AS Country,
		S.CompanyName AS Company,
		SUM(OD.Quantity * OD.UnitPrice) Total
FROM Orders O
JOIN Shippers S ON S.ShipperID = O.ShipVia
JOIN [Order Details] OD ON OD.OrderID = O.OrderID
GROUP BY O.ShipCountry, S.CompanyName

--PIVOT query:
SELECT	[Country], [Speedy Express], [United Package], [Federal Shipping]
FROM
	(SELECT	O.ShipCountry AS Country,
		S.CompanyName AS Company,
		SUM(OD.Quantity * OD.UnitPrice) Total
	FROM Orders O
	JOIN Shippers S ON S.ShipperID = O.ShipVia
	JOIN [Order Details] OD ON OD.OrderID = O.OrderID
	GROUP BY O.ShipCountry, S.CompanyName) Query
PIVOT
(
SUM(Query.Total)
FOR Company IN ([Speedy Express], [United Package], [Federal Shipping])
) AS Total