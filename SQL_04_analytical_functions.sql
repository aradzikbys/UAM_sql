--EX01
select round(avg(UnitPrice),2) AvgPrice
from Products;

--EX02
select	C.CategoryName,
		round(avg(P.UnitPrice),2) AvgPrice
from Products P
join Categories C on C.CategoryID = P.CategoryID
group by C.CategoryName;

--EX03
select *
from Categories

/*Korzystaj¹c z tabel Products oraz Categories zaprojektuj zapytanie, które zwróci wszystkie produkty
(ProductName) wraz z kategoriami, do których nale¿¹ (CategoryName) oraz œredni¹ jednostkow¹ cenê
dla wszystkich produktów. Analiza powinna obejmowaæ produkty ze wszystkich kategorii z wyj¹tkiem
Beverages. Wynik posortuj alfabetycznie po nazwie produktu.*/

select	P.ProductName,
		C.CategoryName,
		round(avg(P.UnitPrice) over (),2) as AvgPrice
from Products P
join Categories C on C.CategoryID = P.CategoryID
where C.CategoryName != 'Beverages'
order by P.ProductName;


--EX04
select	P.ProductName,
		C.CategoryName,
		round(avg(P.UnitPrice) over (),2) as AvgPrice,
		round(min(P.UnitPrice) over (),2) as MinPrice,
		round(max(P.UnitPrice) over (),2) as MaxPrice
from Products P
join Categories C on C.CategoryID = P.CategoryID
order by P.ProductName;

--EX05
select	P.ProductName,
		C.CategoryName,
		round(avg(P.UnitPrice) over (),2) as AvgPrice,
		round(min(P.UnitPrice) over (),2) as MinPrice,
		round(max(P.UnitPrice) over (),2) as MaxPrice,
		round(avg(P.UnitPrice) over (partition by C.CategoryID),2) as AvgPricePerCat,
		round(avg(P.UnitPrice) over (partition by S.SupplierID),2) as AvgPricePerSup
from Products P
join Categories C on C.CategoryID = P.CategoryID
join Suppliers S on S.SupplierID = P.SupplierID
order by P.ProductName;

--EX06
select	P.ProductName,
		C.CategoryName,
		round(avg(P.UnitPrice) over (),2) as AvgPrice,
		round(min(P.UnitPrice) over (),2) as MinPrice,
		round(max(P.UnitPrice) over (),2) as MaxPrice,
		round(avg(P.UnitPrice) over (partition by C.CategoryID),2) as AvgPricePerCat,
		round(avg(P.UnitPrice) over (partition by S.SupplierID),2) as AvgPricePerSup,
		count(P.ProductID) over (partition by C.CategoryID) as NumberOfProd
from Products P
join Categories C on C.CategoryID = P.CategoryID
join Suppliers S on S.SupplierID = P.SupplierID
order by P.ProductName;

--EX07
select	O.OrderID,
		C.CompanyName,
		row_number() over (order by O.OrderDate) RowNum
from Orders O
join Customers C on C.CustomerID = O.CustomerID
order by O.OrderID;

--EX08
select	O.OrderID,
		C.CompanyName,
		row_number() over (order by O.OrderID) RowNum
from Orders O
join Customers C on C.CustomerID = O.CustomerID
order by C.CompanyName, O.OrderDate desc;

--EX09
declare
	@pageNum as int = 3,
	@pageSize as int = 15;

with OrdersWithRowNum (rowNum, ProductID, ProductName, CategoryName, UnitPrice, AvgPricePerCat) as
	(
	select	row_number() over (order by P.ProductID) as rowNum,
			P.ProductID,
			P.ProductName,
			C.CategoryName,
			P.UnitPrice,
			round(avg(P.UnitPrice) over (partition by C.CategoryID),2) as AvgPricePerCat
	from Products P
	join Categories C on C.CategoryID = P.CategoryID
	)

select	ProductID,
		ProductName,
		CategoryName,
		UnitPrice,
		AvgPricePerCat,
		@pageNum as pageNum
from OrdersWithRowNum
where rowNum between (@pageNum - 1)*@pagesize + 1
	and @pageNum * @pageSize
order by ProductName;

--EX10
with TotalRank (ProductID, ProductName, CategoryName, UnitPrice, Ranking) as
	(
	select	P.ProductID,
			P.ProductName,
			C.CategoryName,
			P.UnitPrice,
			rank() over (partition by C.CategoryName order by UnitPrice desc) Ranking
	from Products P
	join Categories C on C.CategoryID = P.CategoryID
	)

select ProductID, ProductName, CategoryName, UnitPrice, Ranking
from TotalRank
where Ranking <= 5;

--EX11
select distinct	query.ProductID,
				query.ProductName
from (
	select	P.ProductID,
			P.ProductName,
			max(OD.UnitPrice * OD.Quantity) over (partition  by P.ProductID) as MaxProdVal,
			avg(OD.UnitPrice * OD.Quantity) over (partition  by P.CategoryID) as AvgCatVal
	from Products P
	join [Order Details] OD on OD.ProductID = P.ProductID
	) query

where query.MaxProdVal < query.AvgCatVal
order by query.ProductID;

--EX12
select	P.ProductID,
		C.CategoryName,
		P.UnitPrice,
		sum(P.UnitPrice) over	(partition by P.CategoryID
								order by P.CategoryID, P.UnitPrice) as RunTotal
from Products P
join Categories C on C.CategoryID = P.CategoryID
order by P.CategoryID, P.UnitPrice;

--EX13
select	P.ProductID,
		C.CategoryName,
		P.UnitPrice,
		sum(P.UnitPrice) over	(partition by P.CategoryID
								order by P.CategoryID, P.UnitPrice) as RunTotal,
		round(avg(P.UnitPrice) over	(partition by P.CategoryID
								order by P.CategoryID, P.UnitPrice
								rows between 2 preceding and current row),2) as AvgUnitPrice,
		round(max(P.UnitPrice) over	(partition by P.CategoryID
								order by P.CategoryID, P.UnitPrice
								rows between 2 preceding and 2 following),2) as MaxUnitPrice
from Products P
join Categories C on C.CategoryID = P.CategoryID
order by P.CategoryID, P.UnitPrice;

--EX14
with Query (ProductID, CategoryName, UnitPrice, RunTotal, MaxUnitPrice, AvgUnitPrice) as (
		select	P.ProductID,
				C.CategoryName,
				P.UnitPrice,
				sum(P.UnitPrice) over	(partition by P.CategoryID
										order by P.CategoryID, P.UnitPrice) as RunTotal,
				round(max(P.UnitPrice) over	(partition by P.CategoryID
										order by P.CategoryID, P.UnitPrice
										rows between 2 preceding and 2 following),2) as MaxUnitPrice,
				round(avg(P.UnitPrice) over	(partition by P.CategoryID
										order by P.CategoryID, P.UnitPrice
										rows between 2 preceding and current row),2) as AvgUnitPrice
		from Products P
		join Categories C on C.CategoryID = P.CategoryID)

select	ProductID,
		CategoryName,
		UnitPrice,
		RunTotal,
		MaxUnitPrice,
		AvgUnitPrice,
		AvgUnitPrice - lag(AvgUnitPrice,1) over (partition by CategoryName
												order by CategoryName, UnitPrice) as Diff

from Query



--EX15 -- REMOVING DUPLICATES -- IMPORTANT
IF OBJECT_ID('dbo.MyCategories') IS NOT NULL DROP TABLE dbo.MyCategories;

SELECT * INTO dbo.MyCategories
FROM dbo.Categories

UNION ALL
SELECT * FROM dbo.Categories
UNION ALL
SELECT * FROM dbo.Categoriesselect * from MyCategories--15A:--select unique values from query > then you can insert it to new table:with CTE as 	(select CategoryID,			CategoryName,			Description,			Picture,			row_number() over						(partition  by	CategoryID						order by CategoryID) as row_num	from MyCategories)select	CategoryID,		CategoryName,		Description,		Picturefrom CTEwhere row_num = 1;--delete duplicated values:with CTE as 	(select CategoryID,			CategoryName,			Description,			Picture,			row_number() over						(partition  by	CategoryID						order by CategoryID) as row_num	from MyCategories	)delete from CTEwhere row_num > 1;	select *from MyCategories
--EX16 -- GAPS -- OLA
select	s.ShippedDate - s.Diff + 1 as RangeStart,
		s.ShippedDate - 1 as RangeEnd

from	(select ShippedDate,
		cast(ShippedDate - lag(ShippedDate,1) over (order by ShippedDate) as int) as Diff
		from Orders) s
where s.Diff is not null and s.Diff > 1
order by s.ShippedDate;


--EX19 -- ISLANDS
