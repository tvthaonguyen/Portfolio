SELECT *
FROM [Portfolio].[dbo].[Nashville Housing]

--Standize Date Format
UPDATE [Portfolio].[dbo].[Nashville Housing]
SET SaleDate = CONVERT(Date,SaleDate)
-------------------------------------------------------------------------------------------------
--- Populate PropertyAddress data
-------ParcelID Giong nhau thi dia chi giong nhau
SELECT a.UniqueID, a.ParcelID, a.PropertyAddress, 
		b.UniqueID, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM [Portfolio].[dbo].[Nashville Housing] a
JOIN [Portfolio].[dbo].[Nashville Housing] b
ON a.ParcelID=b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE b.PropertyAddress is null

UPDATE b
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM [Portfolio].[dbo].[Nashville Housing] a
JOIN [Portfolio].[dbo].[Nashville Housing] b
ON a.ParcelID=b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE b.PropertyAddress is null
----------------------------------------------------------------
--Breaking out PropertyAddress into Invidual Columns (Address, City)
SELECT SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,len(PropertyAddress)) AS City
FROM [Portfolio].[dbo].[Nashville Housing]

ALTER TABLE [Portfolio].[dbo].[Nashville Housing]
ADD PropertySplitAddress nvarchar(255);

UPDATE [Portfolio].[dbo].[Nashville Housing]
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1);

ALTER TABLE [Portfolio].[dbo].[Nashville Housing]
ADD PropertyCity nvarchar(255);

UPDATE [Portfolio].[dbo].[Nashville Housing]
SET PropertyCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,len(PropertyAddress))

-------------------------------------------------------------------
--Breaking out OwnerAddress into Invidual Columns (Address, City, State)
SELECT 
	PARSENAME(REPLACE(OwnerAddress,',','.'),1) as State,
	PARSENAME(REPLACE(OwnerAddress,',','.'),2) as City,
	PARSENAME(REPLACE(OwnerAddress,',','.'),3) as Address
FROM [Portfolio].[dbo].[Nashville Housing]

ALTER TABLE [Portfolio].[dbo].[Nashville Housing]
ADD OwnerSplitAddress nvarchar(255);

UPDATE [Portfolio].[dbo].[Nashville Housing]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE [Portfolio].[dbo].[Nashville Housing]
ADD OwnerSplitCity nvarchar(255);

UPDATE [Portfolio].[dbo].[Nashville Housing]
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)


ALTER TABLE [Portfolio].[dbo].[Nashville Housing]
ADD OwnerSplitState nvarchar(255);

UPDATE [Portfolio].[dbo].[Nashville Housing]
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

-------------------------------------------
--Change 1 and 0 to Yes and No

--Step 1: Check
SELECT DISTINCT(SoldAsVacant)
FROM [Portfolio].[dbo].[Nashville Housing]
--Step 2: Doi kieu du lieu
ALTER TABLE [Portfolio].[dbo].[Nashville Housing]
ALTER COLUMN SoldAsVacant nvarchar(10)
--Step 3: Update
UPDATE [Portfolio].[dbo].[Nashville Housing]
SET SoldAsVacant=
			CASE WHEN SoldAsVacant = '0' THEN 'NO'
				 WHEN SoldAsVacant = '1' THEN 'YES'
			END

--------------------------------------------
--Remove duplicates
With rownumberCTE as (
	SELECT *,ROW_NUMBER() OVER(PARTITION BY [ParcelID]
										,[PropertyAddress]
										,[SaleDate]
										,[SalePrice]
									    ,[LegalReference]
							 ORDER BY [UniqueID]) as rownumber
	FROM [Portfolio].[dbo].[Nashville Housing])

DELETE FROM rownumberCTE
WHERE rownumber>1

----------------------------------------------
--Delete Unused Columns
ALTER TABLE [Portfolio].[dbo].[Nashville Housing]
DROP COLUMN [OwnerAddress], 
			[PropertyAddress],
			[TaxDistrict]

