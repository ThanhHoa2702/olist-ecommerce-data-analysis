
---------------------------------***** Create a testing environment *****---------------------------------

--------------------------------- Staging_customers ---------------------------------
CREATE TABLE Staging_Customers (
	customer_id VARCHAR(50),
	customer_unique_id VARCHAR(50),
	customer_zip_code_prefix VARCHAR(50),
	customer_city VARCHAR(50),
	customer_state VARCHAR(50)
);
--------------------------------- Staging_orders ---------------------------------
CREATE TABLE Staging_orders (
	order_id VARCHAR(50),
	customer_id VARCHAR(50),
	order_status VARCHAR(50),
	order_purchase_timestamps VARCHAR(50),
	order_approved_at VARCHAR(50),
	order_delivered_carrier_date VARCHAR(50),
	order_delivered_customer_date VARCHAR(50),
	order_estimated_delivery_date VARCHAR(50)
);

--------------------------------- Staging_order_items ---------------------------------

CREATE TABLE Staging_order_items (
	order_id VARCHAR(50),
	order_item_id VARCHAR(50),
	product_id VARCHAR(50),
	seller_id VARCHAR(50),
	shipping_limit_date VARCHAR(50),
	price VARCHAR(50),
	freight_value VARCHAR(50)
);

--------------------------------- Staging_products ---------------------------------

CREATE TABLE Staging_products (
	product_id VARCHAR(50),
	product_category_name VARCHAR(50),
	product_name_lenght VARCHAR(50),
	product_description_lenght VARCHAR(50),
	product_photos_qty VARCHAR(50),
	product_weight_g VARCHAR(50),
	product_length_cm VARCHAR(50),
	product_height_cm VARCHAR(50),
	product_width_cm VARCHAR(50)
);

--------------------------------- Staging_product_category_name_Trans ---------------------------------
CREATE TABLE Staging_product_category_name_Trans (
	product_category_name VARCHAR(50),
	product_category_name_english VARCHAR(50)
);


---------------------------------****** DATA QUALITY CHECK ******---------------------------------

--------------------------------- Customers Table ---------------------------------

---- Overview
SELECT * 
FROM Staging_Customers; 
 
---- Duplicate Data

SELECT 
	COUNT(*) AS Total_customers,
	COUNT(DISTINCT customer_id) AS Unique_customer_id,
	COUNT(DISTINCT customer_unique_id) AS Unique_id
FROM Staging_Customers;

---- Null Data
SELECT
	COUNT(CASE WHEN customer_id IS NULL THEN 1 END) AS customer_id_NULL,
	COUNT(CASE WHEN customer_unique_id IS NULL THEN 1 END) AS unique_id_NULL,
	COUNT(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 END) AS zip_code_NULL,
	COUNT(CASE WHEN customer_city IS NULL THEN 1 END) AS city_NULL,
	COUNT(CASE WHEN customer_state IS NULL THEN 1 END) AS state_NULL
FROM Staging_Customers; 

--------------------------------- Orders Table ---------------------------------

---- Overview
SELECT * 
FROM Staging_Orders; 

---- Duplicate Data
SELECT 
	COUNT(order_id) AS Total_order,
	COUNT(DISTINCT order_id) AS Unique_order_id,
	COUNT(DISTINCT customer_id) AS unique_customer_id
FROM staging_orders; 
					 
---- Null Data

SELECT	
	COUNT(CASE WHEN order_id IS NULL THEN 1 END) AS order_NULL,
	COUNT(CASE WHEN customer_id IS NULL THEN 1 END) AS customer_id_NULL,
	COUNT(CASE WHEN order_status IS NULL THEN 1 END) AS order_status_NULL,
	COUNT(CASE WHEN order_purchase_timestamps IS NULL THEN 1 END) purchase_NULL
FROM staging_orders; -- Check the order_status value: If order_status is NULL => Data error
					 -- Check order_purchase_times_stamps value: If NULL appears at the customer time => Data error, system error 

-- Check the logic defining the order status.

SELECT order_status
FROM Staging_Orders
GROUP BY order_status
ORDER BY order_status ASC; -- There are 8 order states. Each order is assigned a state, each representing a different data lifecycle.
						   -- The state will have different attributes (TIMESTAMPS). This is to check if the timeline logic is faulty.
						   -- Based on the states, we can deduce which time logic is allowed to be empty or not,...

-- 1) 'approved'
SELECT *
FROM staging_orders
WHERE order_status = 'approved' 
	AND (order_purchase_timestamps IS NULL OR -- 1. Error: No time to create order
		 order_approved_at IS NULL OR -- 2. Error: No order confirmation time available.
		 order_delivered_carrier_date IS NOT NULL OR -- 3. Error: shipped
		 order_delivered_customer_date IS NOT NULL); -- 4. Error: Delivery
		 
-- 2) 'canceled'
SELECT *
FROM staging_orders
WHERE order_status = 'canceled' 
	AND order_purchase_timestamps IS NULL; -- The error shows the order status as cancelled even though there was no order placement time.
										  -- The remaining time periods may be blank or not..
		 
-- 3) 'created'
SELECT *
FROM staging_orders
WHERE order_status = 'created' 
	AND (order_purchase_timestamps IS NULL OR -- 1. Error: No time to create order 
		 order_approved_at IS NOT NULL OR -- 2. Error: Order confirmation time is available but status does not change.
		 order_delivered_carrier_date IS NOT NULL OR -- 3.Error: shipped time
		 order_delivered_customer_date IS NOT NULL); -- 4. Error: delivery time

-- 4) 'delivered'
SELECT 
	*
FROM staging_orders
WHERE order_status = 'delivered' 
	AND (order_purchase_timestamps IS NULL OR -- 1. Error: No time to create order
		 order_approved_at IS NULL OR -- 2. Error: No order confirmation time available
		 order_delivered_carrier_date IS NULL OR -- 3. Error: shipped time
		 order_delivered_customer_date IS NULL); -- 4. Error: delivery time
	--- => 23 orders were found to have errors in the timing logic.
	
-- Count the orders in each error.
SELECT 
	COUNT(CASE WHEN order_purchase_timestamps IS NULL THEN 1 END) AS Error1,
	COUNT(CASE WHEN order_approved_at IS NULL THEN 1 END) AS Error2, 
	COUNT(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 END) AS Error3,
	COUNT(CASE WHEN order_delivered_customer_date IS NULL THEN 1 END) AS Error4
FROM staging_orders
WHERE order_status = 'delivered';  -- Do not add up the number of errors => number of defective orders

-- 5) 'invoiced'
SELECT *
FROM staging_orders
WHERE order_status = 'invoiced' 
	AND (order_purchase_timestamps IS NULL OR -- 1. Error: No time to create order
		 order_approved_at IS NULL OR -- 2. Error: No order confirmation time available
		 order_delivered_carrier_date IS NOT NULL OR -- 3. Error: shipped time
		 order_delivered_customer_date IS NOT NULL); -- 4. Error: delivery time
		 
-- 6) 'processing'
SELECT *
FROM staging_orders
WHERE order_status = 'processing' 
	AND (order_purchase_timestamps IS NULL OR -- 1. Error: No time to create order
		 order_approved_at IS NULL OR -- 2. Error: No order confirmation time available 
		 order_delivered_carrier_date IS NOT NULL OR -- 3. Error: shipped time
		 order_delivered_customer_date IS NOT NULL); -- 4. Error: delivery time
		 
-- 7) 'shipped'
SELECT *
FROM staging_orders
WHERE order_status = 'shipped' 
	AND (order_purchase_timestamps IS NULL OR -- 1. Error: No time to create order
		 order_approved_at IS NULL OR -- 2. Error: No order confirmation time available  
		 order_delivered_carrier_date IS NULL OR -- 3. Error: shipped time
		 order_delivered_customer_date IS NOT NULL); -- 4. Error: delivery time
		 
-- 8) 'unavailable'
SELECT *
FROM staging_orders
WHERE order_status = 'unavailable' 
	AND (order_purchase_timestamps IS NULL OR -- 1. Lỗi: No time to create order
		 order_approved_at IS NULL OR -- 2. Error: No order confirmation time available   
		 order_delivered_carrier_date IS NOT NULL OR -- 3. Error: shipped time
		 order_delivered_customer_date IS NOT NULL);  -- 4. Error: delivery time

-- Check which order statuses have incorrect timing logic.
WITH orders_1 AS (
	SELECT 
		order_status,
		CAST(order_purchase_timestamps AS TIMESTAMP) AS purchase,
		CAST(order_approved_at AS TIMESTAMP) AS approved_at,
		CAST(order_delivered_carrier_date AS TIMESTAMP) AS delivered_carrier,
		CAST(order_delivered_customer_date AS TIMESTAMP) AS delivered_customer
	FROM staging_orders
)
SELECT 
	order_status, COUNT(order_status)
FROM orders_1
WHERE --- Order lifecycle logic: Catching errors in the wrong timeline.
	purchase > approved_at OR
	approved_at > delivered_carrier OR
	delivered_carrier > delivered_customer 
GROUP BY order_status; -- 1373 The order was delivered successfully, but there was a logic error in the timing.
					   -- 9 The order is in the process of being delivered.
					   -- => 1382 The order has a time-related logic error.

--------------------------------- Order items Table ---------------------------------

-- Overview
SELECT *
FROM Staging_order_items;


-- Duplicate Data
SELECT 
	COUNT(*) AS Total_order_items,
	COUNT(DISTINCT order_id) AS Unique_id,
	COUNT(DISTINCT product_id) AS product_id,
	COUNT(DISTINCT seller_id) AS seller_id
FROM Staging_order_items; 

---- Null Data
SELECT 
	COUNT(CASE WHEN order_id IS NULL THEN 1 END) AS order_id_NULL,
	COUNT(CASE WHEN order_item_id IS NULL THEN 1 END) AS order_item_id_error,
	COUNT(CASE WHEN product_id IS NULL THEN 1 END) AS product_id_NULL,
	COUNT(CASE WHEN seller_id IS NULL THEN 1 END) AS seller_id_NULL,
	COUNT(CASE WHEN shipping_limit_date IS NULL THEN 1 END) AS shipping_NULL,
	COUNT(CASE WHEN price IS NULL THEN 1 END) AS price_error,
	COUNT(CASE WHEN freight_value IS NULL THEN 1 END) AS freight_error
FROM Staging_order_items;

-- Check if the values are incorrect.
WITH order_items_1 AS (
	SELECT 
		CAST(order_item_id AS INT) AS item_id,
		CAST(price AS DECIMAL(10,2)) AS price_1,
		CAST(freight_value AS DECIMAL(10,2)) AS freight_val1
	FROM Staging_order_items
)
SELECT COUNT(*)
FROM order_items_1
WHERE 
	item_id <= 0 OR
	price_1 <= 0 OR
	freight_val1 < 0;

--------------------------------- Order products Table ---------------------------------

---- Overview
SELECT *
FROM Staging_products

---- Duplicate Data
SELECT 
	COUNT(*) AS Total_product,
	COUNT(DISTINCT product_id) AS product_id,
	COUNT(DISTINCT product_category_name) AS category_name
FROM staging_products; -- There are 73 product categories based on the data.

---- Null Data
SELECT 
	COUNT(CASE WHEN product_id IS NULL THEN 1 END) AS id_NULL,
	COUNT(CASE WHEN product_category_name IS NULL THEN 1 END) AS category_name,
	COUNT(CASE WHEN product_name_lenght IS NULL THEN 1 END) AS name_lenght_NULL,
	COUNT(CASE WHEN product_description_lenght IS NULL THEN 1 END) AS description_lenght_NULL,
	COUNT(CASE WHEN product_photos_qty IS NULL THEN 1 END) AS photos_qty_NULL,
	COUNT(CASE WHEN product_weight_g IS NULL THEN 1 END) AS weight_g_NULL,
	COUNT(CASE WHEN product_length_cm IS NULL THEN 1 END) AS length_NULL,
	COUNT(CASE WHEN product_height_cm IS NULL THEN 1 END) AS height_NULL,
	COUNT(CASE WHEN product_width_cm IS NULL THEN 1 END) AS width_NULL
FROM staging_products; -- There are 610 rows of NULL data in 4 columns, representing categories with blank names.

---- Check the catalog
SELECT product_category_name
FROM staging_products
GROUP BY product_category_name; -- There are 73 product category names, and 1 category has no name.
								-- Proceed to check the number of orders for the unnamed category in the next step.

--------------------------------- Product category name translation Table ---------------------------------

---- Overview
SELECT * 
FROM staging_product_category_name_trans;

---- Duplicate Data
SELECT 
	COUNT(*) AS Total_name,
	COUNT(DISTINCT product_category_name) AS category_name,
	COUNT(DISTINCT product_category_name_english) AS category_name_E
FROM staging_product_category_name_trans; -- The order items table has 73 categories, but the translation table only has 71 categories translated into English.

---- Null Data
SELECT 
	COUNT(CASE WHEN product_category_name IS NULL THEN 1 END ) AS name_NULL,
	COUNT(CASE WHEN product_category_name_english IS NULL THEN 1 END ) AS name2_NULL
FROM staging_product_category_name_trans;

---------------------------------****** Data Integrity. ******---------------------------------

--------------------------------- Orders Table & Customers Table ---------------------------------

-- Check the customer ID when an order is created but there is no customer information in the customers table.
SELECT
	o.order_id,
	o.customer_id
FROM staging_orders AS o
LEFT JOIN staging_customers AS cus
ON o.customer_id = cus.customer_id
WHERE cus.customer_id IS NULL; 

--------------------------------- Orders Table & Order_items Table ---------------------------------

-- Order_ID that exist in the order_items table but DO NOT EXIST in the orders table.
SELECT 
	DISTINCT(items.order_id) AS orphan_order_id
FROM staging_order_items AS items
LEFT JOIN staging_orders AS o
ON items.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Order_ID that exist in the orders table but DO NOT exist in the order_items table.
SELECT 
	o.order_status, 
	COUNT(o.order_status)
FROM staging_orders AS o
LEFT JOIN staging_order_items AS items
ON o.order_id = items.order_id
WHERE items.order_id IS NULL 
GROUP BY o.order_status -- 775 orders have NO product information or price.

--------------------------------- Order_items Table & Products Table ---------------------------------

-- The products sold in the order do not have IDs in the Product Catalog.
SELECT 
    items.order_id, 
    prod.product_id AS orphan_product_id
FROM staging_order_items AS items
LEFT JOIN staging_products AS prod 
    ON items.product_id = prod.product_id
WHERE prod.product_id IS NULL;

-- The orders listed in the table do not have product category names.
SELECT 
	items.order_id,
    prod.product_id,
    prod.product_category_name
FROM staging_products AS prod
LEFT JOIN staging_order_items AS items
ON prod.product_id = items.product_id
WHERE  prod.product_category_name IS NULL
GROUP BY items.order_id, prod.product_id, prod.product_category_name;

-- Query the orders and funding sources for unnamed products. 
WITH order_items_1 AS (
SELECT
		order_id,
		product_id,
		seller_id,
		CAST(order_item_id AS INT) AS item_quantity,
		CAST(price AS DECIMAL(10,2)) AS price,
		CAST(freight_value AS DECIMAL(10,2)) AS freight
FROM staging_order_items
) 
SELECT 
	o.order_status, 
	COUNT(DISTINCT o.order_id),
	SUM(items.price) AS Total_price
FROM staging_orders AS o
INNER JOIN order_items_1 AS items
ON o.order_id = items.order_id 
INNER JOIN staging_products AS prod
ON items.product_id = prod.product_id
WHERE prod.product_category_name IS NULL 
GROUP BY  o.order_status 
ORDER BY SUM(items.price) DESC


--------------------------------- Products Table & Product_category_name_trans Table ---------------------------------

-- Categories not included in the Translation table
SELECT 
	DISTINCT(prod.product_category_name)
FROM staging_products AS prod
LEFT JOIN  staging_product_category_name_trans AS trans
ON prod.product_category_name = trans.product_category_name 
WHERE trans.product_category_name IS NULL
	AND prod.product_category_name IS NOT NULL;

---------------------------------****** Data Cleaning and Create Views. *****---------------------------------

--------------------------------- Products Table ---------------------------------
CREATE OR REPLACE VIEW products AS (
	SELECT 
		prod.product_id AS product_id,
		prod.product_category_name AS category_name,
		COALESCE(trans.product_category_name_english,
		--- Translate the two missing categories into English.
				 CASE 
				 	WHEN prod.product_category_name = 'pc_gamer' THEN 'pc_gamer'
					WHEN prod.product_category_name = 'portateis_cozinha_e_preparadores_de_alimentos' THEN 'portable_kitchen_and_food_preparators'
					WHEN prod.product_category_name IS NULL THEN 'Unkown'
				 END) AS category_name_ENG
	FROM staging_products AS prod
	LEFT JOIN staging_product_category_name_trans AS trans
		ON prod.product_category_name = trans.product_category_name 
);

--------------------------------- Customers Table ---------------------------------
CREATE OR REPLACE VIEW customers AS(
	SELECT *
	FROM staging_customers 
);

--------------------------------- Orders Table ---------------------------------
CREATE OR REPLACE VIEW orders AS(
	SELECT 
		-- Keys
		order_id,
		customer_id,
		--  
		order_status,
		--- TIMESTAMP
		
		-- Payment terms
		CAST(order_purchase_timestamps AS TIMESTAMP) AS purchase_timestamp,
		CAST(order_purchase_timestamps AS DATE) AS purchase_date,
		CAST(order_purchase_timestamps AS TIME) AS purchase_time,
		
		-- Order confirmation time
		CAST(order_approved_at AS TIMESTAMP) AS approved_at_timestamp,
		CAST(order_approved_at AS DATE) AS approved_at_date,
		CAST(order_approved_at AS TIME) AS approved_at_time,

		-- Time to hand over to the shipping company
		CAST(order_delivered_carrier_date AS TIMESTAMP) AS delivered_carrier_timestamp,
		CAST(order_delivered_carrier_date AS DATE) AS delivered_carrier_date,
		CAST(order_delivered_carrier_date AS TIME) AS delivered_carrier_time,

		-- Timeframe for customers to receive their orders
		CAST(order_delivered_customer_date AS TIMESTAMP) AS delivered_customer_timestamp,
		CAST(order_delivered_customer_date AS DATE) AS delivered_customer_date,
		CAST(order_delivered_customer_date AS TIME) AS delivered_customer_time,
		
		CAST(order_estimated_delivery_date AS DATE) AS estimated_delivery
FROM staging_orders 
);

--------------------------------- Order_items Table ---------------------------------
CREATE OR REPLACE VIEW order_items AS(
	SELECT
		-- Keys
		order_id,
		product_id,
		seller_id,
		-- Metrics
		CAST(order_item_id AS INT) AS item_quantity,
		CAST(price AS DECIMAL(10,2)) AS price,
		CAST(freight_value AS DECIMAL(10,2)) AS freight,
		CAST(shipping_limit_date AS TIMESTAMP) AS shipping_limit
	FROM staging_order_items
);

----------------------------------------***** Explore *****----------------------------------------

--- Zombie orders in Warehouse
SELECT 
	o.order_id,
	o.order_status,
	o.purchase_timestamp,
	o.approved_at_timestamp,
	o.delivered_carrier_timestamp,
	items.shipping_limit,
	(SELECT MAX(delivered_customer_timestamp) FROM orders) AS Limit_time
FROM orders AS o
LEFT JOIN order_items AS items
ON items.order_id = o.order_id
WHERE order_status IN ('approved','invoiced','processing') -- Status of orders in the Warehouse
	AND ((SELECT MAX(delivered_customer_timestamp) FROM orders) > items.shipping_limit) -- Timeline violation: The system's last data update time has exceeded the deadline.
	AND delivered_carrier_timestamp IS NULL -- No time to give it to the shipping company.
	
--- Aggregate Zombie orders in Warehouse
SELECT 
	o.order_status,
	COUNT(DISTINCT o.order_id),
	SUM(items.price)
FROM orders AS o
LEFT JOIN order_items AS items
ON items.order_id = o.order_id
WHERE order_status IN ('approved','invoiced','processing') -- Status of orders in the Warehouse
	AND ((SELECT MAX(delivered_customer_timestamp) FROM orders) > items.shipping_limit) -- Timeline violation: The system's last data update time has exceeded the deadline.
	AND delivered_carrier_timestamp IS NULL -- No time to give it to the shipping company.
GROUP BY order_status

--- Total Revenue Zombie orders in Warehouse 
SELECT 
	COUNT(DISTINCT o.order_id) AS Warehouse_orders,
	SUM(items.price)
FROM orders AS o
LEFT JOIN order_items AS items
ON items.order_id = o.order_id
WHERE order_status IN ('approved','invoiced','processing') 
	AND ((SELECT MAX(delivered_customer_timestamp) FROM orders) > items.shipping_limit) -- Time limit violation: The system's last data update time has exceeded the deadline.
	AND delivered_carrier_timestamp IS NULL -- No time to give it to the shipping company.
;

---  Aggregate Zombie orders and Risk Cost Zombie orders in Shipping 
SELECT 
	COUNT(DISTINCT o.order_id) AS Shipping_Orders,
	SUM(items.freight) AS Risk_Cost
FROM orders AS o
LEFT JOIN order_items AS items
ON o.order_id = items.order_id
WHERE order_status = 'shipped'
	AND ((SELECT MAX(delivered_customer_date) FROM orders)::DATE - estimated_delivery::DATE > 30) -- Timeline violation: The system's last data update time exceeded the expected time by more than 30 days.
	AND delivered_customer_date IS NULL -- The customer has not received.
;

-- Query the cost of each product category.
SELECT 
	prod.category_name_eng,
	MIN(items.price) AS Min_price,
	MIN(items.freight) AS Min_price,
	AVG(items.price) AS avg_price,
	AVG(items.freight) AS avg_price,
	MAX(items.price) AS Max_price,
	MAX(items.freight) AS Max_freight
FROM order_items AS items
LEFT JOIN products AS prod
ON items.product_id = prod.product_id
GROUP BY prod.category_name_eng
ORDER BY MAX(items.freight) DESC;

-- Tinquire about lost shipping costs. (Actual Sunk Cost)
WITH freight_value_of_Cancellation AS
(SELECT
	*
FROM orders AS o 
LEFT JOIN order_items AS items
ON o.order_id = items.order_id
WHERE order_status = 'canceled' AND
	delivered_carrier_date IS NOT NULL
)
SELECT SUM(freight)
FROM freight_value_of_Cancellation;

-- Inquiry into 141 orders cancelled before confirmation (Pre-Payment)
SELECT 
	o.order_id,
	o.customer_id,
	o.order_status,
	o.purchase_timestamp
FROM orders AS o
LEFT JOIN order_items AS items
ON o.order_id = items.order_id
WHERE order_status = 'canceled' 
	AND approved_at_date IS NULL -- No time to confirm the order.
	AND items.order_id IS NULL -- No information

-- Querying 626 orders with no product information (No Info) - Ware House
SELECT 
	order_status,
	COUNT(order_status)
FROM orders AS o 
LEFT JOIN order_items AS items 
ON o.order_id = items.order_id
WHERE order_status IN ('canceled','unavailable')
	AND o.approved_at_timestamp IS NOT NULL 
	AND items.order_id IS NULL
GROUP BY order_status

-- Product price query across product categories
SELECT
	prod.category_name,
	items.price,
	items.freight
FROM products AS prod
INNER JOIN order_items AS items
ON prod.product_id = items.product_id
GROUP BY items.price, prod.category_name,items.freight
ORDER BY prod.category_name

