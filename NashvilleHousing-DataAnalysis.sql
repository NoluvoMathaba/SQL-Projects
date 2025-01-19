-----1. Cleaning the data
			--First check for null values

SELECT *
FROM NashvilleHousing
WHERE SalePrice IS NULL OR OwnerName IS NULL OR SaleDate IS NULL;

      --STANDARDIZE saleDate FORMAT , CURRENTLY IT IS USING DATETIME AND WE WANT IT TO USE DATE DATATYPE
ALTER TABLE NashvilleHousing
ALTER COLUMN saleDate DATE

      --We have  null property addresses where the parcelId is same as that of another row 
	  --therefore we will populate the addtress with the address used in that other row of same parcelID

UPDATE A
SET PropertyAddress = ISNULL(B.PropertyAddress,A.PropertyAddress)
FROM NashvilleHousing A
JOIN NashvilleHousing B
ON (A.parcelId = B.parcelId and A.UniqueID <> B.UniqueID)
WHERE A.PropertyAddress IS NULL

         -- Changing the Y AND N to YES and NO in the SoldAsVaccant column


UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant='Y' THEN 'YES'
				   WHEN SoldAsVacant='N' THEN 'NO'
				   ELSE SoldAsVacant
				   END

UPDATE NashvilleHousing
SET SalePrice = (SELECT AVG(SalePrice) FROM PropertySales)
WHERE SalePrice IS NULL

           --Remove Leading/Trailing Spaces

UPDATE NashvilleHousing
SET PropertyAddress = LTRIM(RTRIM(PropertyAddress)),
    OwnerName = LTRIM(RTRIM(OwnerName))

	       --Handle Incorrect Data Formats

UPDATE NashvilleHousing
SET Acreage = REPLACE(Acreage, ',', '.')  -- e.g Convert '2,3' to '2.3'
WHERE Acreage LIKE '%,%'


            --Checking for duplicates
SELECT PropertyAddress,SaleDate,LegalReference,SoldAsVacant, COUNT(*)
FROM NashvilleHousing
GROUP BY PropertyAddress,SaleDate,LegalReference,SoldAsVacant
HAVING COUNT(*) > 1


             --Deleting duplicates using a CTE
WITH Duplicates AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY PropertyAddress,SaleDate,LegalReference,SoldAsVacant ORDER BY PropertyAddress,SaleDate,LegalReference,SoldAsVacant) AS RowNum
    FROM NashvilleHousing
)
DELETE FROM Duplicates
WHERE RowNum > 1


---- 2. Filtering properties by saleprice
SELECT * 
FROM NashvilleHousing
WHERE SalePrice > 300000

---- 3. Finding properties sold after a specific date
SELECT * 
FROM NashvilleHousing
WHERE SaleDate > '2016-01-30'


---- 4. Finding average sale price by year
SELECT 
YEAR(SaleDate) AS SaleYear, 
ROUND(AVG(SalePrice),2) AS AvgSalePrice
FROM NashvilleHousing
GROUP BY YEAR(SaleDate)
ORDER BY SaleYear;

---- 5. Top 3 most expensive properties sold
SELECT  TOP 3 * 
FROM NashvilleHousing
ORDER BY SalePrice DESC

---- 6. Sum of building and land values by owners
SELECT 
OwnerName, 
SUM(LandValue) AS TotalLandValue, 
SUM(BuildingValue) AS TotalBuildingValue
FROM NashvilleHousing
GROUP BY OwnerName
ORDER BY TotalLandValue DESC

---- 7. Finding properties by land use
SELECT * 
FROM NashvilleHousing
WHERE LandUse = 'SINGLE FAMILY'


---- 8. Finding Properties Built Before a Specific Year and Sold for Over $300,000 with acreage>2
SELECT * 
FROM NashvilleHousing
WHERE YearBuilt < 2000
AND SalePrice > 300000
AND Acreage>2


---- 9. running total by each district
SELECT TaxDistrict,
PropertyAddress, 
SaleDate, 
SalePrice, 
SUM(SalePrice) OVER (PARTITION BY TaxDistrict ORDER BY SaleDate ) AS RunningTotalByDistrict
FROM NashvilleHousing
WHERE TaxDistrict IS NOT NULL
ORDER BY TaxDistrict, SaleDate

---- 10. Finding the yearly growth in sales 
WITH YearlySales AS (
    SELECT YEAR(SaleDate) AS SaleYear, 
	SUM(SalePrice) AS TotalSales
    FROM NashvilleHousing
    GROUP BY YEAR(SaleDate)
)
SELECT SaleYear,
       TotalSales,
       LAG(TotalSales) OVER (ORDER BY SaleYear) AS PreviousYearSales,
       ROUND((TotalSales - LAG(TotalSales) OVER (ORDER BY SaleYear)) / LAG(TotalSales) OVER (ORDER BY SaleYear) * 100,2) AS SalesGrowthPercentage
FROM YearlySales
ORDER BY SaleYear

---- 11. top 3 properties with the highest SalePrice in each TaxDistrict
WITH RankedProperties AS (
    SELECT UniqueID, 
	PropertyAddress, 
	SalePrice, 
	TaxDistrict,
    ROW_NUMBER() OVER (PARTITION BY TaxDistrict ORDER BY SalePrice DESC) AS Rank
    FROM NashvilleHousing
	WHERE TaxDistrict IS NOT NULL
)
SELECT UniqueID, 
PropertyAddress, 
SalePrice, 
TaxDistrict
FROM RankedProperties
WHERE Rank <= 3
ORDER BY TaxDistrict, SalePrice DESC

---- 12.Finding total sales per LandUse (e.g., SINGLE FAMILY, COMMERCIAL, etc.) for each year
SELECT YEAR(SaleDate) AS SaleYear, 
LandUse, 
SUM(SalePrice) AS TotalSales
FROM NashvilleHousing
GROUP BY YEAR(SaleDate), LandUse
ORDER BY SaleYear, TotalSales DESC

---- 13. Finding properties sold within the last 100 days
SELECT 
UniqueID, 
PropertyAddress, 
SaleDate, 
SalePrice
FROM NashvilleHousing
WHERE SaleDate >= DATEADD(DAY, -100, GETDATE())

---- 14. Cumulative Average SalePrice Over Time
SELECT 
UniqueID, 
PropertyAddress, 
SaleDate, 
SalePrice,
AVG(SalePrice) OVER (ORDER BY SaleDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumulativeAverageSalePrice
FROM NashvilleHousing
ORDER BY SaleDate

---- 15. Properties Sold Below Their Total Value
SELECT 
UniqueID, 
PropertyAddress, 
SalePrice, 
TotalValue
FROM NashvilleHousing
WHERE SalePrice < TotalValue


---- 16. Properties with the Largest Difference Between Sale Price and Land Value
SELECT TOP 10 UniqueID, 
PropertyAddress, 
SalePrice, 
LandValue, (
SalePrice - LandValue) AS PriceLandDifference
FROM NashvilleHousing
ORDER BY PriceLandDifference DESC
