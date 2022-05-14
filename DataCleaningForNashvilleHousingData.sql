-- Cleaning Data using SQL Queries

Select *
From dbo.NashvilleHousingData


-- Standardize Date Format

Select SaleDate, Convert(Date, SaleDate)
From dbo.NashvilleHousingData

Update NashvilleHousingData
Set SaleDate = Convert(Date, SaleDate)

-- Using another method we can standard the date format as follows

Alter Table NashvilleHousingData
Add SaleDateStandardized Date;

Update NashvilleHousingData
Set SaleDateStandardized  = Convert(Date, SaleDate)

Select SaleDateStandardized , Convert(Date, SaleDate)
From dbo.NashvilleHousingData

-- Populate Property Address Data

-- We discover that there are many instances where property address is null
-- However from the below query we can see that same ParcelIDs always have the same Propert address

Select *
From dbo.NashvilleHousingData
order by ParcelID

-- We can then use this logic to complete other property addresses that are null

Select a.ParcelID, a.PropertyAddress, b.ParcelID, a.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From dbo.NashvilleHousingData a
Join dbo.NashvilleHousingData b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
Where a.PropertyAddress is null

Update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From dbo.NashvilleHousingData a
Join dbo.NashvilleHousingData b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
Where a.PropertyAddress is null


-- Let's break down address into separate columns for address, city and state

Select PropertyAddress
From dbo.NashvilleHousingData

Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
From dbo.NashvilleHousingData

Alter Table NashvilleHousingData
Add PropertySplitAddress NVARCHAR(255);

Update NashvilleHousingData
Set PropertySplitAddress  = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

Alter Table NashvilleHousingData
Add PropertySplitCity NVARCHAR(255);

Update NashvilleHousingData
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


-- Checking to confirm Property Address column has been split
Select *
From dbo.NashvilleHousingData

-- Let's split the Owner address column into address, city and states
-- This time we'll use the parsename which works only on periods

Select OwnerAddress
From dbo.NashvilleHousingData

Select
PARSENAME(REPLACE(OwnerAddress,',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)
From dbo.NashvilleHousingData

Alter Table NashvilleHousingData
Add OwnerSplitAddress NVARCHAR(255);

Update NashvilleHousingData
Set OwnerSplitAddress  = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3)

Alter Table NashvilleHousingData
Add OwnerSplitCity NVARCHAR(255);

Update NashvilleHousingData
Set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',', '.'), 2)

Alter Table NashvilleHousingData
Add OwnerSplitState NVARCHAR(255);

Update NashvilleHousingData
Set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)

Select *
From dbo.NashvilleHousingData

-- Checking to confirm Owner Address column has been split
Select *
From dbo.NashvilleHousingData

-- Looking at the 'Sold as  Vacant' Column, the values there are not consistent

Select Distinct(SoldAsVacant), Count(SoldASVacant) as Total
From dbo.NashvilleHousingData
Group by SoldAsVacant
Order by 2

-- Change 'Y' and 'N' to 'Yes' and 'No' in 'Sold as Vacant' Column

Select SoldAsVacant,
Case	When SoldAsVacant =  'Y' Then 'Yes'
		When SoldAsVacant = 'N' Then 'No'
		Else SoldAsVacant
		End
From dbo.NashvilleHousingData

Update NashvilleHousingData
Set SoldAsVacant = Case When SoldAsVacant =  'Y' Then 'Yes'
		When SoldAsVacant = 'N' Then 'No'
		Else SoldAsVacant
		End

-- Confirm if change works

Select Distinct(SoldAsVacant), Count(SoldASVacant) as Total
From dbo.NashvilleHousingData
Group by SoldAsVacant
Order by 2


-- Remove Duplicates (Best Practice - do not do this on raw date. Always try to avoid this)
-- We'll use a CTE for this

With RowNumCTE As (
Select *,
ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SaleDate,
				SalePrice,
				LegalReference
				Order by
					UniqueID
				) row_num

From dbo.NashvilleHousingData
)
--We can see row numbers greater than 1 are duplicates, so we delete these

Delete
From RowNumCTE
Where row_num > 1

-- Checking to confrim duplicates have been deleted

With RowNumCTE As (
Select *,
ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SaleDate,
				SalePrice,
				LegalReference
				Order by
					UniqueID
				) row_num

From dbo.NashvilleHousingData
)
--We can see row numbers greater than 1 are duplicates, so we delete these

Select *
From RowNumCTE
Where row_num > 1


-- Delete unused columns (Best Practice - do not do this on raw date. Always try to avoid this)

Alter Table NashvilleHousingData
Drop Column PropertyAddress, SaleDate, OwnerAddress

-- Confirm if columns have indeed been dropped
Select *
From dbo.NashvilleHousingData






