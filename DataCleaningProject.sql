/************* Data Cleaning Project *************/

/*
In this project the main goal is to clean data in order to create insights 
from the data once the raw data has been cleansed into clean data. The data 
was imported from an excel file that contains data about housing in Nashville,
Tennesse.
*/

/** Cleansing Data in SQL Queries **/

--Calling the correct database which contains the data in question.
USE NashvilleHousingData
-------------------------------------------------------------------------------------------------------------------------------------------

--Previewing the housing data.
SELECT *
FROM dbo.NHD;
--------------------------------------------------------------------------------------------------------------------------------------------

--Standardize the sales date format.

--Try to format the sales date using the update clause but the change would not consistently take effect. 
UPDATE dbo.NHD
SET SaleDate = CONVERT(DATE, SaleDate);

--Used alter table clause in order to create a new table.
ALTER TABLE dbo.NHD
ADD SaleDateCon DATE;

--Then populated the new table with the standardized sales date format.
UPDATE dbo.NHD
SET SaleDateCon = CONVERT(DATE, SaleDate);
----------------------------------------------------------------------------------------------------------------------------------------------

--Populate Property Address Data

--Previewing the how the property address displayed in the table. 
SELECT PropertyAddress
FROM dbo.NHD;

--Determing if there is any null values in the property address column.
SELECT ParcelID, PropertyAddress
FROM dbo.NHD
WHERE PropertyAddress IS NULL;

--The select statement that will allow us to populate the null Property Addresses.
SELECT
	a.ParcelID,
	a.PropertyAddress,
	b.ParcelID,
	b.PropertyAddress,
	ISNULL(a.PropertyAddress, b.PropertyAddress) AS 'Populated Column'
FROM dbo.NHD a
JOIN dbo.NHD b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

--Updating all the property addresses with null values. 
--When updating table while using a join statement have to use the alias name.
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.NHD a
JOIN dbo.NHD b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;
----------------------------------------------------------------------------------------------------------------------------------------

--Split Address into Individual Columns (Address, City, State)

--The SQL code below will allow for the extraction of the Address.
SELECT
	SUBSTRING(PropertyAddress, 1, (CHARINDEX(',', PropertyAddress) - 1)) AS 'Address'
FROM dbo.NHD

--The SQL code below will allow for the extraction of the city
SELECT
	SUBSTRING(PropertyAddress, (CHARINDEX(',', PropertyAddress) + 1), LEN(PropertyAddress)) AS 'City'
FROM dbo.NHD 

--The addition of two new columns which will contain the address and city of the property.
ALTER TABLE dbo.NHD
ADD
	Property_Address NVARCHAR(150),
	Property_City NVARCHAR(150);

--The Property_Address column is getting populated with the necessary data.
UPDATE dbo.NHD
SET Property_Address = SUBSTRING(PropertyAddress, 1, (CHARINDEX(',', PropertyAddress) - 1));

--The Property_City colum is getting populated with the necessary data.
UPDATE dbo.NHD
SET Property_City = SUBSTRING(PropertyAddress, (CHARINDEX(',', PropertyAddress) + 1), LEN(PropertyAddress));

--Now lets split up the owner address in the same way as the property address.
--In addition, the owner address also contains the state.
--The PARSENAME function was used in this situation to divide the owner address into three parts.
--PARSENAME divides a string into sections and the period is used as a delimiter.
--The first section begins from the right side of the string or inversed. 
SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS 'Address',
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS 'City',
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS 'State'
FROM dbo.NHD;

--The addition of three new columns which will contain the address, city, and state of the owner.
ALTER TABLE dbo.NHD
ADD
	Owner_Address NVARCHAR(150),
	Owner_City NVARCHAR(150),
	Owner_State NVARCHAR(10);

--The Owner_Address column is getting populated with the necessary data.
UPDATE dbo.NHD
SET Owner_Address = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

--The Owner_City column is getting populated with the necessary data.
UPDATE dbo.NHD
SET Owner_City = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

--The Owner_State column is getting populated with the necessary data.
UPDATE dbo.NHD
SET Owner_State = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);
------------------------------------------------------------------------------------------------------------------------------------------

--Change Y and N to Yes and No in the "Sold as Vacant" field.

--Lets preview how the data looks in this certain field
SELECT 
	DISTINCT SoldAsVacant AS 'DistinctValues',
	COUNT(SoldASVacant) AS 'Count'
FROM dbo.NHD
GROUP BY SoldAsVacant
ORDER BY 2;

--Creation of the query that will help make the changes or modifications.
SELECT
	SoldAsVacant,
	CASE
		WHEN SoldAsVacant = 'N' THEN 'No'
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		ELSE SoldAsVacant
	END AS 'ChangedSoldAsVacant'
FROM dbo.NHD

--Update statement to change certain values in the 'SoldAsVacant'field.
UPDATE dbo.NHD
SET SoldAsVacant =
	CASE
		WHEN SoldAsVacant = 'N' THEN 'No'
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		ELSE SoldAsVacant
	END;

--Make sure if the data got updated correctly. 
SELECT 
	DISTINCT SoldAsVacant AS 'DistinctValues',
	COUNT(SoldASVacant) AS 'Count'
FROM dbo.NHD
GROUP BY SoldAsVacant
ORDER BY 2;
-----------------------------------------------------------------------------------------------------------------------------------------------------

--Remove Duplicates

--Creation of a temp table.
WITH RowNumCte AS(
	SELECT 
		*,
		ROW_NUMBER() OVER(
			PARTITION BY
				ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
			ORDER BY
				UniqueID) AS 'Row_Num'
FROM dbo.NHD
)

-- Selecting the duplicated rows from the temp table.
SELECT *
FROM RowNumCte
WHERE Row_Num > 1
ORDER BY Property_Address;

--Delete the duplicated data from the temp table.
WITH RowNumCte AS(
	SELECT 
		*,
		ROW_NUMBER() OVER(
			PARTITION BY
				ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
			ORDER BY
				UniqueID) AS 'Row_Num'
FROM dbo.NHD
)

--Deleting the duplicated rows from the temp table.
DELETE 
FROM RowNumCte
WHERE Row_Num > 1;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Delete Unused Columns 

--First lets preview how the data looks with the changes made so far.
SELECT *
FROM dbo.NHD;

--Now deleting columns using the ALTER TABLE clause coupled with the DROP COLUMN clause.
ALTER TABLE dbo.NHD
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress; 

--Forgot to delete one of the columns in the previous SQL code on top.
ALTER TABLE dbo.NHD
DROP COLUMN SaleDate;