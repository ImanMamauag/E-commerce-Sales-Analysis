# Investigating the different categories of the Status column to determine if they are Fulfilled Orders.

SELECT DISTINCT Status
FROM az_sales_staging3;

SELECT Order_ID, Status, Courier_Status, Amount
FROM az_sales_staging3
WHERE Status = 'Shipped - Out for Delivery';


# Status catergories that will be included (completed sales)
-- Shipped 			= fulfilled.
-- Shipped - Delivered to Buyer	= fulfilled.
-- Shipped - Picked Up 		= buyer received order.
-- Shipped - Out for Delivery	= fulfilled.

# Status categories that will be filtered out (not a completed sale / revenue not realized)
-- Cancelled 			= not fulfilled.
-- Pending				= not fulfilled.
-- Pending - Waiting for Pick Up 	= order not completed yet.
-- Shipped - Returned to Seller 	= revenue reversed.
-- Shipped - Returning to Seller 	= not fulfilled.
-- Shipped - Rejected by Buyer 	= not fulfilled.
-- Shipped - Lost in Transit 	= not fulfilled.
-- Shipped - Damaged 		= not fulfilled.
-- Shipping			= not fulfilled.

# Investigating also in the Courier_Status column
# Checking the Amount column values of the category 'Unshipped' in Courier Status
SELECT Ship_State AS region,
		SUM(Amount) AS total_sales
FROM az_sales_staging3
WHERE Courier_Status = 'Unshipped'
GROUP BY Ship_State
ORDER BY total_sales DESC;

# 'Unshipped' have values in the Amount Column
 
# Checking the Amount Column values for 'Cancelled' tag in Courier Status
SELECT Ship_State AS region,
		SUM(Amount) AS total_sales
FROM az_sales_staging3
WHERE Courier_Status = 'Cancelled'
GROUP BY Ship_State
ORDER BY total_sales DESC;

# The 'Cancelled' category has 0 values in the Amount Column

# Decided to FILTER OUT Courier Status with 'Unshipped', 'Cancelled' and '' tag. 
# It represents an order attempt, but it wasn't fulfilled, it doesn't contribute to actual revenue/sales.

# Computing the Gross Sales

SELECT SUM(Amount)
FROM az_sales_staging3;

# Computing the Gross vs. Unfulfilled Sales
SELECT
    SUM(Amount) AS Gross_Sales,
	(SELECT SUM(Amount)
	FROM az_sales_staging3
	WHERE Status IN ('Cancelled',
					'Pending',
					'Pending - Waiting for Pick Up',
					'Shipped - Returned to Seller',
					'Shipped - Returning to Seller',
					'Shipped - Rejected by Buyer',
					'Shipped - Lost in Transit',
					'Shipped - Damaged',
					'Shipping')) AS Unfulfilled_Sales
FROM az_sales_staging3;

# Computing the Net Sales

SELECT SUM(Amount)
FROM az_sales_staging3
WHERE Status IN ('Shipped', 
				'Shipped - Delivered to Buyer', 
                'Shipped - Picked Up', 
                'Shipped - Out for Delivery');



# Net Sales per Region(State)

SELECT Ship_State AS region,
		SUM(Amount) AS total_sales
FROM az_sales_staging3
WHERE Status IN ('Shipped', 
				 'Shipped - Delivered to Buyer', 
                 'Shipped - Picked Up', 
                 'Shipped - Out for Delivery')
GROUP BY region
ORDER BY total_sales DESC;

# Average Order Value 

SELECT
SUM(Amount) * 1.0/ COUNT(DISTINCT Order_ID) AS avg_order_value 
FROM az_sales_staging3 
WHERE Status IN ('Shipped', 
				 'Shipped - Delivered to Buyer', 
                 'Shipped - Picked Up', 
                 'Shipped - Out for Delivery');


# AOV by Customer Type (B2B)  

SELECT
SUM(Amount) / COUNT(DISTINCT Order_ID) AS avg_order_value,
SUM(Amount) as total_sales_b2b
FROM az_sales_staging3
WHERE Status IN ('Shipped', 
				 'Shipped - Delivered to Buyer', 
                 'Shipped - Picked Up', 
                 'Shipped - Out for Delivery')
	AND B2B = 'TRUE';

# AOV by Customer Type (Customer)
SELECT
SUM(Amount) / COUNT(DISTINCT Order_ID) AS avg_order_value,
SUM(Amount) as total_sales_b2b
FROM az_sales_staging3
WHERE Status IN ('Shipped', 
				 'Shipped - Delivered to Buyer', 
                 'Shipped - Picked Up', 
                 'Shipped - Out for Delivery')
	AND B2B = 'FALSE';

# Insight: AOV of B2B > B2C


# Units Per Order/Transaction
SELECT
SUM(Qty)/ COUNT(DISTINCT Order_ID) AS units_per_order 
FROM az_sales_staging3 
WHERE Status IN ('Shipped', 
				 'Shipped - Delivered to Buyer', 
                 'Shipped - Picked Up', 
                 'Shipped - Out for Delivery');


# Most popular product category per region.
# CTE, Window Function
WITH sales_per_region AS (
    SELECT Ship_State AS region,
           Category,
           SUM(Amount) AS total_sales
    FROM az_sales_staging3
    WHERE Status IN ('Shipped', 
				 'Shipped - Delivered to Buyer', 
                 'Shipped - Picked Up', 
                 'Shipped - Out for Delivery')
    GROUP BY Ship_State, Category
),
ranked AS (
    SELECT region,
           Category,
           total_sales,
           RANK() OVER (PARTITION BY region ORDER BY total_sales DESC) AS rnk
    FROM sales_per_region
)
SELECT region,
       Category AS most_popular_category,
       total_sales
FROM ranked
WHERE rnk = 1
ORDER BY total_sales DESC;

# Total Orders Received

SELECT COUNT(Order_ID)
FROM az_sales_staging3;

# Total Orders Fullfiled 

SELECT COUNT(Order_ID) as total_orders_fulfilled
FROM az_sales_staging3
WHERE Status IN ('Shipped', 
				 'Shipped - Delivered to Buyer', 
                 'Shipped - Picked Up', 
                 'Shipped - Out for Delivery');

# Total Orders Cancelled 

SELECT COUNT(Order_ID) as total_orders_cancelled
FROM az_sales_staging3
WHERE Status NOT IN ('Shipped', 
				 'Shipped - Delivered to Buyer', 
                 'Shipped - Picked Up', 
                 'Shipped - Out for Delivery');
                 

# Total Orders Fullfiled per Region(State)

SELECT Ship_State AS region,
		COUNT(Order_ID) as total_order
FROM az_sales_staging3
WHERE Status IN ('Shipped', 
				 'Shipped - Delivered to Buyer', 
                 'Shipped - Picked Up', 
                 'Shipped - Out for Delivery')
GROUP BY Ship_State
ORDER BY total_order DESC;

# Monthly Net Sales
SELECT SUBSTRING(`Date`,1,7) AS `MONTH`, SUM(Amount)
FROM az_sales_staging3
WHERE Status IN ('Shipped', 
				 'Shipped - Delivered to Buyer', 
                 'Shipped - Picked Up', 
                 'Shipped - Out for Delivery')
GROUP BY `MONTH`
ORDER BY `MONTH`; 

# Monthly Net Sales (moving average)
WITH monthly_sales AS (
    SELECT 
        SUBSTRING(`Date`, 1, 7) AS `MONTH`,
        SUM(Amount) AS total_sales
    FROM az_sales_staging3
    WHERE Status IN (
        'Shipped', 
        'Shipped - Delivered to Buyer', 
        'Shipped - Picked Up', 
        'Shipped - Out for Delivery'
    )
    GROUP BY SUBSTRING(`Date`, 1, 7)
)
SELECT 
    `MONTH`,
    total_sales,
    ROUND(
        AVG(total_sales) OVER (
            ORDER BY `MONTH`
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS moving_avg_3m
FROM monthly_sales
ORDER BY `MONTH`;

# Courier Status Total Count/Day
SELECT 
    SUBSTRING(`Date`, 1, 10) AS `DAY`,
    Courier_Status,
    COUNT(*) AS order_count
FROM az_sales_staging3
WHERE Courier_Status <> ''
GROUP BY SUBSTRING(`Date`, 1, 10), Courier_Status
ORDER BY DAY, Courier_Status;


    
