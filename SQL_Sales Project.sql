/****** Script for SelectTopNRows command from SSMS  ******/
--Cleaned Dim_customer table
SELECT c.[CustomerKey]
      ,c.[FirstName]
      ,c.[LastName]
	  ,c.[FirstName]+' '+c.[LastName] as FullName
	  ,Case c.Gender when 'M' then 'Male' else 'Female' end as Gender
      ,c.[DateFirstPurchase]
      ,g.city as Customer_City
FROM [AdventureWorksDW2017].[dbo].[DimCustomer] as c
  LEFT JOIN dimGeography as g
	ON C.GeographyKey = g.GeographyKey
ORDER BY CustomerKey

--Cleaned DimDate table-
SELECT  [DateKey]
      ,[FullDateAlternateKey] as Date
      ,[EnglishDayNameOfWeek] as Day
      ,[WeekNumberOfYear]
      ,[EnglishMonthName] as Month
	  , left([EnglishMonthName],3) as Month_short
      ,[MonthNumberOfYear] as MonthNO
      ,[CalendarQuarter] as Quarter
      ,[CalendarYear] as Year
  FROM [AdventureWorksDW2017].[dbo].[DimDate]
  WHERE [CalendarYear]>=2019

--Cleaned DimProduct table-
SELECT p.[ProductKey]
      ,p.[ProductAlternateKey] as ProductItemCode
      ,p.[EnglishProductName] as [Product Name]
	  ,pc.[EnglishProductCategoryName] as [Category Name]
	  ,ps.[EnglishProductSubcategoryName] as [Subcategory Name]
      ,p.[Color]
      ,p.[Size]
      ,p.[ProductLine]
      ,p.[ModelName]
      ,isnull(p.[Status],'Outdated') as [Product Status]
FROM [AdventureWorksDW2017].[dbo].[DimProduct] as p
  LEFT JOIN [AdventureWorksDW2017].[dbo].[DimProductSubcategory] AS ps
			ON p.[ProductSubcategoryKey]=ps.[ProductSubcategoryKey]
  LEFT JOIN [AdventureWorksDW2017].[dbo].[DimProductCategory] AS pc 
			ON ps.[ProductCategoryKey]=pc.[ProductCategoryKey]
ORDER BY ProductKey

--Cleaned Fact_InternetSale table-
SELECT [ProductKey]
      ,[OrderDateKey]
      ,[DueDateKey]
      ,[ShipDateKey]
      ,[CustomerKey]
      ,[SalesOrderNumber]
      ,[SalesAmount]
FROM [AdventureWorksDW2017].[dbo].[FactInternetSales]
WHERE left([OrderDateKey],4)>=2019
ORDER BY ProductKey
  