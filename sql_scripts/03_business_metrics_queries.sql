

----------------------------------------***** Khám phá dữ liệu *****----------------------------------------

-- Failed Orders Analysis 
CREATE OR REPLACE VIEW Cancellation_Group AS (
SELECT
	order_id,
	customer_id,
	order_status,
	purchase_timestamp,
	approved_at_timestamp,
	delivered_carrier_timestamp,
	delivered_customer_timestamp,
	(CASE 
		WHEN purchase_timestamp IS NOT NULL AND approved_at_timestamp IS NULL THEN '1. Pre_Payment'
		WHEN approved_at_timestamp IS NOT NULL AND delivered_carrier_date IS NULL THEN '2. Before_Shipping'
		WHEN delivered_carrier_date IS NOT NULL AND delivered_customer_date IS NULL THEN '3. Failed Delivery'
	ELSE '4. Customer Return' END) AS Cancellation_Reasons_Group 
FROM  orders
WHERE order_status IN ('canceled','unavailable')
);

-- Failed Orders Table 
SELECT 
	Cancellation_Reasons_Group,
	COUNT(order_id)
FROM Cancellation_Group
GROUP BY Cancellation_Reasons_Group 
ORDER BY Cancellation_Reasons_Group ASC;


-- Canceled Orders in (Pre-Payment)
SELECT
	can.order_status,
	COUNT(DISTINCT(can.order_id))
FROM Cancellation_Group AS can 
LEFT JOIN order_items AS items
ON can.order_id = items.order_id
WHERE can.order_status IN ('canceled','unavailable') 
	AND (items.order_id IS NOT NULL OR items.order_id IS NULL)
	AND can.approved_at_timestamp IS NULL
GROUP BY can.order_status;

-- Canceled Orders with Has Item info in 2. Before Shipping 
SELECT
	can.order_status,
	COUNT(DISTINCT(can.order_id))
FROM Cancellation_Group AS can 
LEFT JOIN order_items AS items
ON can.order_id = items.order_id
WHERE can.order_status IN ('canceled','unavailable') 
	AND items.order_id IS NOT NULL
	AND can.approved_at_timestamp IS NOT NULL
	AND can.delivered_carrier_timestamp IS NULL
GROUP BY can.order_status;

-- Canceled Orders with No item info in 2. Before Shipping 
SELECT
	can.order_status,
	COUNT(DISTINCT(can.order_id))
FROM Cancellation_Group AS can 
LEFT JOIN order_items AS items
ON can.order_id = items.order_id
WHERE can.order_status IN ('canceled','unavailable') 
	AND items.order_id IS NULL
	AND can.approved_at_timestamp IS NOT NULL
	AND can.delivered_carrier_timestamp IS NULL
GROUP BY can.order_status;


--- Create a table summarizing zombie orders  in the warehouse.

CREATE OR REPLACE VIEW Zombie_orders_table AS (
SELECT 
	DISTINCT(o.order_id),
	o.order_status,
	o.purchase_timestamp,
	o.approved_at_timestamp,
	o.delivered_carrier_timestamp,
	items.shipping_limit
FROM orders AS o
LEFT JOIN order_items AS items
ON items.order_id = o.order_id
WHERE 
	-- Trạng thái những đơn hàng thuộc Warehouse
(	order_status IN ('approved','invoiced','processing') 
	-- Vi phạm mốc thời gian: thời gian cập nhật dữ liệu cuối cùng của hệ thống vượt qua mốc
	AND ((SELECT MAX(delivered_customer_timestamp) FROM orders) > items.shipping_limit) 
	AND delivered_carrier_timestamp IS NULL)
OR  --- Trạng thái những đơn hàng thuộc Shipped 
(	order_status = 'shipped' 
	-- Vi phạm mốc thời gian: Thời gian cập nhật dữ liệu cuối cùng của hệ thống vượt qua thời gian dự kiến > 30 days
	AND (SELECT MAX(delivered_customer_date) FROM orders)::DATE - estimated_delivery::DATE > 30) 
	AND delivered_customer_date IS NULL);

-- Tổng hợp các trạng thái có đơn hàng treo
SELECT 
	order_status,
	COUNT(DISTINCT order_id)
FROM Zombie_orders_table
GROUP BY order_status;

-- Risk Revenue of Zombie Orders
SELECT 
	zo.order_status,
	COUNT(DISTINCT zo.order_id),
	MIN(items.price) AS Min_price,
	ROUND(AVG(items.price)) AS Mean_price,
	MAX(items.price) AS Max_price,
	SUM(items.price) AS Total_Rick_Revenue
FROM Zombie_orders_table AS zo
LEFT JOIN order_items AS items
ON zo.order_id = items.order_id
GROUP BY order_status;

--- Chi phí vận chuyển rủi ro trong Shipping 
SELECT 
	COUNT(DISTINCT zo.order_id) AS Shipping_Orders,
	SUM(items.freight) AS Risk_Cost
FROM Zombie_orders_table AS zo
LEFT JOIN order_items AS items
ON zo.order_id = items.order_id
WHERE zo.order_status = 'shipped';

-- Truy vấn chi phí của từng danh mục sản phẩm
SELECT 
	prod.category_name_eng,
	MIN(items.price) AS Min_price,
	MIN(items.freight) AS Min_price,
	ROUND(AVG(items.price),2) AS avg_price,
	ROUND(AVG(items.freight),2) AS avg_price,
	MAX(items.price) AS Max_price,
	MAX(items.freight) AS Max_freight
FROM order_items AS items
LEFT JOIN products AS prod
ON items.product_id = prod.product_id
GROUP BY prod.category_name_eng;

-- Truy vấn chi phí ship bị thất thoát (Actual Sunk Cost)

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

-- Truy vấn giá sản phẩm các ngành hàng 
SELECT 
	prod.category_name,
	items.price,
	items.freight
FROM products AS prod
INNER JOIN order_items AS items
ON prod.product_id = items.product_id
GROUP BY items.price, prod.category_name,items.freight
ORDER BY prod.category_name;
 
-- Truy vấn các đơn huỷ và không khả dụng trên toàn hệ thống 
SELECT 
	order_status,
	COUNT(order_id)
FROM orders
GROUP BY order_status
HAVING order_status IN ('canceled', 'unavailable');



