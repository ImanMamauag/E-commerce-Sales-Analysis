-- Create new database


CREATE DATABASE IF NOT EXISTS ecommerce_db;

USE ecommerce_db;

-- Create new table 


CREATE TABLE az_sales
(
Row_Num INT,
Order_ID TEXT,
Date TEXT,	
Status TEXT,
Fulfilment TEXT,
Sales_Channel TEXT,
Ship_Service_Level TEXT,
Style  TEXT,
SKU TEXT,
Category TEXT,
Size TEXT,
ASIN TEXT,
Courier_Status TEXT,
Qty INT,
Currency TEXT,
Amount TEXT,
Ship_City TEXT,
Ship_State TEXT,
Ship_Postal_Code TEXT,
Ship_Country TEXT,
Promotion_IDs TEXT,
B2B TEXT,
Fulfilled_By TEXT
);

SELECT * 
FROM az_sales;

-- Import Data 


LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Amazon Sale Report Raw.csv' INTO TABLE az_sales
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 1 LINES;

-- Data Cleaning

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null or Blank Values
-- 4. Remove Any Columns


-- Creating a staging table for data cleaning process
CREATE TABLE az_sales_staging
LIKE az_sales;

SELECT * FROM az_sales_staging;


-- Importing all data from raw table to staging.
INSERT az_sales_staging 
SELECT * FROM az_sales;

-- Removing duplicates


-- Identifying duplicate rows in az_sales_staging by grouping on (Order_ID, Date, Status, Fulfilment, SKU, Category, Amount).
-- Within each group, the first row is marked rn = 1, while any additional rows (rn > 1) are considered duplicates.

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY Order_ID, `Date`, Status, Fulfilment, SKU, Category, Amount) AS rn
FROM az_sales_staging;

WITH duplicate_cte AS(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY Order_ID, `Date`, Status, Fulfilment, SKU, Category, Amount) AS rn
FROM az_sales_staging
)

SELECT * FROM duplicate_cte
WHERE rn > 1;

-- 6 values identified

-- Double checking if values are duplicates.
SELECT * FROM az_sales_staging
WHERE Order_ID = '171-3249942-2207542';

-- Creating another staging table because duplicates couldn’t be removed directly in the CTE.

CREATE TABLE `az_sales_staging2` (
  `Row_Num` int DEFAULT NULL,
  `Order_ID` text,
  `Date` text,
  `Status` text,
  `Fulfilment` text,
  `Sales_Channel` text,
  `Ship_Service_Level` text,
  `Style` text,
  `SKU` text,
  `Category` text,
  `Size` text,
  `ASIN` text,
  `Courier_Status` text,
  `Qty` int DEFAULT NULL,
  `Currency` text,
  `Amount` text,
  `Ship_City` text,
  `Ship_State` text,
  `Ship_Postal_Code` text,
  `Ship_Country` text,
  `Promotion_IDs` text,
  `B2B` text,
  `Fulfilled_By` text,
  `rn` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


SELECT * FROM az_sales_staging2;

-- Importing all data from staging 1 to staging 2 with an added row_num column
INSERT INTO az_sales_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY Order_ID, `Date`, Status, Fulfilment, SKU, Category, Amount
) AS rn
FROM az_sales_staging;

SELECT *
FROM az_sales_staging2
WHERE rn > 1;

-- Finally we can delete the duplicate rows in the staging 2 table 
DELETE
FROM az_sales_staging2
WHERE rn > 1;

SELECT *
FROM az_sales_staging2
WHERE rn > 1;

-- Checking cleaning progress
SELECT *
FROM az_sales_staging2;




-- Standardizing Data


SELECT DISTINCT Category, TRIM(Category) 
FROM az_sales_staging2;
-- Identified one value is not in Proper Case

-- Checking the supposed value for kurta
SELECT Category 
FROM az_sales_staging2
WHERE Category = 'kurta';

-- Updating kurta to a Proper Case
UPDATE az_sales_staging2
SET Category = 'Kurta'
WHERE Category = 'kurta';

-- Checking by column
SELECT DISTINCT Ship_State
FROM az_sales_staging2
ORDER BY 1;

-- Checking by value
SELECT Ship_State 
FROM az_sales_staging2
WHERE Ship_State LIKE 'new del%';

-- Updating value #1 in Ship_State column
UPDATE az_sales_staging2 
SET Ship_State = 'GUJARAT'
WHERE Ship_State = 'Gujarat';

-- Updating value #2 in Ship_State column
UPDATE az_sales_staging2 
SET Ship_State = 'NEW DELHI'
WHERE Ship_State = 'New Delhi';

-- Updating value #3 in Ship_State column
UPDATE az_sales_staging2 
SET Ship_State = 'GOA'
WHERE Ship_State = 'Goa';

-- And updating a couple more... 

-- will fill missing with 'No Promotion'
UPDATE az_sales_staging2 
SET Promotion_IDs = 'No Promotion'
WHERE Promotion_IDs = '';

-- Checking if there are still blanks
SELECT Promotion_IDs
FROM az_sales_staging2
WHERE Promotion_IDs = ''; 


SELECT `Date`,
str_to_date(`Date`, '%m/%d/%Y')
FROM az_sales_staging2;

-- Update date format first YYYY-MM--DD
UPDATE az_sales_staging2
SET `Date` = str_to_date(`Date`, '%m/%d/%Y');

SELECT `Date`
FROM az_sales_staging2;

-- Then update data type from TEXT to DATE
ALTER TABLE az_sales_staging2
MODIFY COLUMN `Date` DATE;

-- turn blanks into 0
UPDATE az_sales_staging2
SET Amount = '0'
WHERE Amount = '' OR Amount IS NULL OR Amount = 'NULL';

-- Checking if there are blanks
SELECT * FROM
az_sales_staging2
WHERE Amount = '';

-- Update data type of 'Amount' column from TEXT to DOUBLE
ALTER TABLE az_sales_staging2
MODIFY COLUMN `Amount` DECIMAL(10,2);



-- Null or Blank Values


SELECT *
FROM az_sales_staging2
WHERE Amount = '';

SELECT *
FROM az_sales_staging2;az_sales_staging2az_sales_staging2az_sales_staging3


-- Creating another staging table to delete rows with Amount = ''
CREATE TABLE `az_sales_staging3` (
  `Row_Num` int DEFAULT NULL,
  `Order_ID` text,
  `Date` date DEFAULT NULL,
  `Status` text,
  `Fulfilment` text,
  `Sales_Channel` text,
  `Ship_Service_Level` text,
  `Style` text,
  `SKU` text,
  `Category` text,
  `Size` text,
  `ASIN` text,
  `Courier_Status` text,
  `Qty` int DEFAULT NULL,
  `Currency` text,
  `Amount` text,
  `Ship_City` text,
  `Ship_State` text,
  `Ship_Postal_Code` text,
  `Ship_Country` text,
  `Promotion_IDs` text,
  `B2B` text,
  `Fulfilled_By` text,
  `rn` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Import all data from staging 2 to staging 3
INSERT INTO az_sales_staging3
SELECT * 
FROM az_sales_staging2;


SELECT * 
FROM az_sales_staging3;


SELECT * 
FROM az_sales_staging3
WHERE  Amount = 0.00
AND Qty IN ('0', NULL)
AND Status IN ('Cancelled', 'Shipped - Returned to Seller')
AND Courier_Status = 'Cancelled';

-- Double-checking the rows we’re about to remove before running the DELETE

SELECT COUNT(*) AS rows_to_delete
FROM az_sales_staging3
WHERE Amount = 0.00
  AND (Qty = 0 OR Qty IS NULL)
  AND Status IN ('Cancelled', 'Pending', 'Shipping')
  AND Courier_Status = 'Cancelled';

-- Chose to retain the null and dirty data, as they will not significantly impact the EDA process.


SELECT *
FROM az_sales_staging3
WHERE Amount = 0.00
  AND (Qty = 0 OR Qty IS NULL)
  AND Status IN ('Cancelled', 'Shipped - Returned to Seller')
  AND Courier_Status = 'Cancelled';

SELECT COUNT(*) AS rows_to_delete 
FROM az_sales_staging3
WHERE  Amount = 0.00;


SELECT DISTINCT(B2B)
FROM az_sales_staging3;


SELECT * FROM az_sales_staging3;


-- Remove Any Columns

-- not needed
ALTER TABLE az_sales_staging3
DROP COLUMN Row_Num;

-- not needed 
ALTER TABLE az_sales_staging3
DROP COLUMN rn;

-- only value was amazon courier "easy-ship" with no other relationship
ALTER TABLE az_sales_staging3
DROP COLUMN Fulfilled_By;
