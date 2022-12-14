-- EX01
if object_id (N'dbo.OrderAmt', N'FN') is not null
	drop function dbo.OrderAmt;
go

create function dbo.OrderAmt(@OrderID INT)
returns money
as
begin
	declare @OAmt money

	select @OAmt = sum(OD.Quantity * OD.UnitPrice)
	from [Order Details] OD
	where @OrderID = OD.OrderID
	

	if (@OAmt is null)
		set @OAmt = 0;

	return @OAmt;
end;
go

--healthcheck:
select dbo.OrderAmt(NULL) as OrderAmt
select dbo.OrderAmt(10259) as OrderAmt
select dbo.OrderAmt(111111) as OrderAmt


-- EX02
select	OrderID,
		CustomerID,
		OrderDate,
		dbo.OrderAmt(OrderID) as OrderAmt
from Orders
order by OrderID;


-- EX03
if object_id (N'dbo.employeeInfo', N'IF') is not null
	drop function dbo.employeeInfo;
go

create function dbo.employeeInfo(@OrderID INT)
returns table
as
return (
	select	E.FirstName,
			E.LastName,
			E.Address
	from Orders O
	join Employees E on E.EmployeeID = O.EmployeeID
	where @OrderID = O.OrderID
)
go

--healthcheck:
select FirstName, LastName, Address from dbo.employeeInfo(10248)
union all
select FirstName, LastName, Address from dbo.employeeInfo(NULL)
union all
select FirstName, LastName, Address from dbo.employeeInfo(0)


-- EX04
if object_id (N'dbo.employeeInfoExt', N'IF') is not null
	drop function dbo.employeeInfoExt;

go

/*
That one below WON'T return comments for missing OrderID or OrderID = null
create function dbo.employeeInfoExt(@OrderID INT)
returns table
as
return (
	select	E.FirstName,
			E.LastName,
			E.Address,
			case
				when @OrderID in (select OrderID from Orders) then concat('Order ID:', cast(@OrderID as varchar))
				when @OrderID is null then 'Really? NULL?!'
				when @OrderID not in (select OrderID from Orders) then 'There is no such an OrderID'
			end as Comment
	from Orders O
	join Employees E on E.EmployeeID = O.EmployeeID
	--for OrderID = null or OrderID not in Orders > "where" below with stop query
	where @OrderID = O.OrderID
	)
go
*/

create function dbo.employeeInfoExt(@OrderID INT)
returns table
as
return (
	select	E.FirstName,
			E.LastName,
			E.Address,
			case
				when @OrderID in (select OrderID from Orders) then concat('Order ID:', cast(@OrderID as varchar))
				when @OrderID is null then 'Really? NULL?!'
				when @OrderID not in (select OrderID from Orders) then 'There is no such an OrderID'
			end as Comment
	from Orders O
	join Employees E on E.EmployeeID = O.EmployeeID
	--for OrderID = null or OrderID not in Orders > "where" below with stop query
	where @OrderID = O.OrderID
	)

--healthcheck:
select FirstName, LastName, Address, Comment from dbo.employeeInfoExt(10249)
union all
select FirstName, LastName, Address, Comment from dbo.employeeInfoExt(NULL)
union all
select FirstName, LastName, Address, Comment from dbo.employeeInfoExt(0)-- EX05if object_id (N'dbo.stringsConcat', N'IF') is not null
	drop function dbo.stringsConcat;
go

create function dbo.stringsConcat(@str1 nvarchar(100), @str2 nvarchar(100), @sep nvarchar(10))
returns table
as
return
	(
	select concat(@str1, @sep, @str2) as String
	)
go


SELECT dbo.stringsConcat('Ala ma', 'kota', ' ') AS Result
UNION ALL
SELECT dbo.stringsConcat('Ten znak: ', ' to jest myœlnik', '-') AS Result
UNION ALL
SELECT dbo.stringsConcat('Wiêcej: ', ' myœlników', '---') AS Result
UNION ALL
SELECT dbo.stringsConcat('NULL', 'NULL', ' != ') AS Result
UNION ALL
SELECT dbo.stringsConcat('Prawdziwy NULL', NULL, ': ') AS Result