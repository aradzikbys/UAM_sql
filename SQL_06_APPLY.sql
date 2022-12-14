-- EX01
/* Convert below query to replace JOIN with APPLY. */
-- w/o APPLY:
SELECT	P.ProductID,
		P.ProductName,
		S.CompanyName
FROM Products P
JOIN Suppliers S ON P.SupplierID = S.SupplierID
ORDER BY ProductID--with APPLY:SELECT	P.ProductID,
		P.ProductName,
		S.CompanyName
FROM Products P 
CROSS APPLY Suppliers as S
WHERE S.SupplierID = P.SupplierID
ORDER BY ProductID--EX02/* Using the Orders table and the employeeInfo function, display the order ID, Customer ID,
order date and attendant details (function: employeeInfo: FirstName, LastName).
Sort the result according to the order ID. */IF OBJECT_ID (N'dbo.employeeInfo', N'IF') IS NOT NULL  
    DROP FUNCTION dbo.employeeInfo;  
GO  
CREATE FUNCTION dbo.employeeInfo(@OrderID INT)
RETURNS TABLE   
AS     
RETURN (
	SELECT	E.FirstName, 
			E.LastName,
			E.Address
	FROM	Orders O
	JOIN Employees E ON	O.EmployeeID = E.EmployeeID
	WHERE	O.OrderID = @OrderID
)SELECT	O.OrderID,		O.CustomerID,		O.OrderDate,		E.FirstName,		E.LastNameFROM Orders O CROSS APPLY employeeInfo(O.OrderID) EORDER BY O.OrderID--EX03/* Create a customerInfo function that will be similar to the employeeInfo function except that it
will return customer data: CompanyName, ContactName, Address. */SELECT	DISTINCT
		C.CompanyName,
		C.ContactName,
		C.Address
FROM Orders O
CROSS APPLY Customers C
WHERE C.CustomerID = O.CustomerID

--insert query into function:IF OBJECT_ID (N'dbo.customerInfo', N'IF') IS NOT NULL  
    DROP FUNCTION dbo.customerInfo;  
GO  

CREATE FUNCTION dbo.customerInfo(@OrderID INT)  
RETURNS TABLE   
AS     
RETURN (
		SELECT	C.CompanyName,
				C.ContactName,
				C.Address
		FROM Orders O
		CROSS APPLY Customers C
		WHERE	C.CustomerID = O.CustomerID
				AND O.OrderID = @OrderID
		)SELECT * FROM dbo.customerInfo(10248)
UNION ALL
SELECT * FROM dbo.customerInfo(NULL)
UNION ALL
SELECT * FROM dbo.customerInfo(0)

--EX04
/* Update the query from EX02 with customer details: CompanyName, Contact, Address (use
customerInfo function). */

SELECT	O.OrderID,		O.CustomerID,		O.OrderDate,		E.FirstName,		E.LastName,		C.CompanyName,		C.ContactName,		C.AddressFROM Orders O CROSS APPLY employeeInfo(O.OrderID) ECROSS APPLY customerInfo(O.OrderID) CORDER BY O.OrderID--EX05/* Using the Orders, Order Details and Employees tables and the OUTER APPLY operator display the name,
surname, city, region of the employee and the sum of orders by him served (including the discount!).Sort the result in descending order by order value. */SELECT *FROM [Order Details]
SELECT	E.FirstName,
		E.LastName,
		E.City,
		E.Region,
		ROUND(SUM(OD.Quantity * OD.UnitPrice * (1 - OD.Discount)),2) AS OrdersValue
FROM Orders O
OUTER APPLY [Order Details] OD
OUTER APPLY Employees E
WHERE	E.EmployeeID = O.EmployeeID
		AND OD.OrderID = O.OrderID
GROUP BY E.FirstName, E.LastName, E.City, E.Region
ORDER BY OrdersValue DESC;
