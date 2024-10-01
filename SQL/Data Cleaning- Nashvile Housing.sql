SELECT * FROM housing.`nashville housing data for data cleaning`;

USE housing;
RENAME TABLE `nashville housing data for data cleaning` TO nashville_housing;

SELECT * FROM nashville_housing;

-- Standardize date format
UPDATE nashville_housing
SET SaleDate = STR_TO_DATE(SaleDate, '%M %d, %Y');

-- Populate property address data
UPDATE nashville_housing AS a
JOIN nashville_housing AS b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

-- Breaking out address into individual columns
SELECT
SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1) AS address,
SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress)) AS city
FROM nashville_housing;

-- Drop the Address column if it exists
ALTER TABLE nashville_housing
DROP COLUMN Address;

ALTER TABLE nashville_housing
ADD Address VARCHAR(255);

UPDATE nashville_housing
SET Address = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1);

ALTER TABLE nashville_housing
ADD PropertyCity VARCHAR(255);

UPDATE nashville_housing
SET PropertyCity = TRIM(SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress)));

-- Owner Address (Address, City, State)
SELECT 
    SUBSTRING_INDEX(OwnerAddress, ',', 1) AS StreetAddress,
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS City,
    SUBSTRING_INDEX(OwnerAddress, ',', -1) AS State
FROM nashville_housing;

ALTER TABLE nashville_housing
ADD OwnerStreetAddress VARCHAR(255);

UPDATE nashville_housing
SET OwnerStreetAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE nashville_housing
ADD OwnerCityAddress VARCHAR(255);

UPDATE nashville_housing
SET OwnerCityAddress = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

ALTER TABLE nashville_housing
ADD OwnerStateAddress VARCHAR(255);

UPDATE nashville_housing
SET OwnerStateAddress = SUBSTRING_INDEX(OwnerAddress, ',', -1);

-- Change Y and N to Yes and No in 'Sold as Vacant' field
UPDATE nashville_housing
SET SoldAsVacant = 
	CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END;

-- Remove duplicates
-- This are the duplicates:
WITH row_numCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID,
                         PropertyAddress,
                         SalePrice,
                         SaleDate,
                         LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM nashville_housing
)
SELECT *
FROM row_numCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

-- Remove the duplicates:
-- Step 1: Create a temporary table
CREATE TEMPORARY TABLE temp_unique_rows AS
SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM nashville_housing
) AS subquery
WHERE row_num = 1;  -- Keep only the first row of each duplicate group

-- Step 2: Delete all rows from the original table
DELETE FROM nashville_housing;

-- Step 3: Insert unique rows back into the original table
INSERT INTO nashville_housing
SELECT * FROM temp_unique_rows;

-- Optional: Drop the temporary table if no longer needed
DROP TEMPORARY TABLE temp_unique_rows;

-- Delete unused columns
ALTER TABLE nashville_housing
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress,
DROP COLUMN SaleDate;

SELECT * FROM nashville_housing;