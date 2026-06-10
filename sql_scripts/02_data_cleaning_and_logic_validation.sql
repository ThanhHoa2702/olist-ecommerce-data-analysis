---------------------------------****** Kiểm tra cầu nối, toàn vẹn dữ liệu ******---------------------------------

--------------------------------- Bảng orders và customers ---------------------------------

-- Kiểm tra id khách hàng khi đơn hàng được tạo mà không có thông tin khách hàng trong bảng customers
SELECT
	o.order_id,
	o.customer_id
FROM staging_orders AS o
LEFT JOIN staging_customers AS cus
ON o.customer_id = cus.customer_id
WHERE cus.customer_id IS NULL; 

--------------------------------- Bảng orders và orders_items ---------------------------------

-- Những order_id có trong bảng order_items nhưng KHÔNG TỒN TẠI trong bảng orders
SELECT 
	DISTINCT(items.order_id) AS orphan_order_id
FROM staging_order_items AS items
LEFT JOIN staging_orders AS o
ON items.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Những order_id có trong bảng orders nhưng KHÔNG TỒN TẠI trong bảng order_items
SELECT 
	o.order_status, 
	COUNT(o.order_status)
FROM staging_orders AS o
LEFT JOIN staging_order_items AS items
ON o.order_id = items.order_id
WHERE items.order_id IS NULL 
GROUP BY o.order_status -- 775 đơn hàng KHÔNG có thông tin, giá sản phẩm

--------------------------------- Bảng order_items và product ---------------------------------

-- Các sản phẩm đã được bán trong đơn hàng không có ID trong Danh mục Sản phẩm
SELECT 
    items.order_id, 
    prod.product_id AS orphan_product_id
FROM staging_order_items AS items
LEFT JOIN staging_products AS prod 
    ON items.product_id = prod.product_id
WHERE prod.product_id IS NULL;

-- Các đơn hàng được giao dịch trong bảng không có tên danh mục sản phẩm 
SELECT 
	items.order_id,
    prod.product_id,
    prod.product_category_name
FROM staging_products AS prod
LEFT JOIN staging_order_items AS items
ON prod.product_id = items.product_id
WHERE  prod.product_category_name IS NULL
GROUP BY items.order_id, prod.product_id, prod.product_category_name;

-- Truy vấn các đơn hàng và nguồn tiền của những sản phẩm không tên. 
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


--------------------------------- Bảng products và product_category_name_trans ---------------------------------

-- Các danh mục không có trong bảng Translation
SELECT 
	DISTINCT(prod.product_category_name)
FROM staging_products AS prod
LEFT JOIN  staging_product_category_name_trans AS trans
ON prod.product_category_name = trans.product_category_name 
WHERE trans.product_category_name IS NULL
	AND prod.product_category_name IS NOT NULL;

---------------------------------****** Tiến hành Làm sạch dữ liệu, Tạo View *****---------------------------------

--------------------------------- Bảng Products ---------------------------------
CREATE OR REPLACE VIEW products AS (
	SELECT 
		prod.product_id AS product_id,
		prod.product_category_name AS category_name,
		COALESCE(trans.product_category_name_english,
		--- Chuyển đổi 2 danh mục còn thiếu sang tiếng anh 
				 CASE 
				 	WHEN prod.product_category_name = 'pc_gamer' THEN 'pc_gamer'
					WHEN prod.product_category_name = 'portateis_cozinha_e_preparadores_de_alimentos' THEN 'portable_kitchen_and_food_preparators'
		-- Đặt tên cho các danh mục bị trống/NULL để tiến hành truy vấn, phân tích
					WHEN prod.product_category_name IS NULL THEN 'Unkown'
				 END) AS category_name_ENG
	FROM staging_products AS prod
	LEFT JOIN staging_product_category_name_trans AS trans
		ON prod.product_category_name = trans.product_category_name 
);

--------------------------------- Bảng customers ---------------------------------
CREATE OR REPLACE VIEW customers AS(
	SELECT *
	FROM staging_customers 
);

--------------------------------- Bảng orders ---------------------------------
CREATE OR REPLACE VIEW orders AS(
	SELECT 
		-- Các khoá 
		order_id,
		customer_id,
		-- Phân loại 
		order_status,
		--- Nhóm thời gian 
		
		-- Thời gian thanh toán 
		CAST(order_purchase_timestamps AS TIMESTAMP) AS purchase_timestamp,
		CAST(order_purchase_timestamps AS DATE) AS purchase_date,
		CAST(order_purchase_timestamps AS TIME) AS purchase_time,
		
		-- Thời gian xác nhận đơn
		CAST(order_approved_at AS TIMESTAMP) AS approved_at_timestamp,
		CAST(order_approved_at AS DATE) AS approved_at_date,
		CAST(order_approved_at AS TIME) AS approved_at_time,

		-- Thời gian đưa cho đơn vị vận chuyển
		CAST(order_delivered_carrier_date AS TIMESTAMP) AS delivered_carrier_timestamp,
		CAST(order_delivered_carrier_date AS DATE) AS delivered_carrier_date,
		CAST(order_delivered_carrier_date AS TIME) AS delivered_carrier_time,

		-- Thời gian khách hàng nhận được đơn hàng
		CAST(order_delivered_customer_date AS TIMESTAMP) AS delivered_customer_timestamp,
		CAST(order_delivered_customer_date AS DATE) AS delivered_customer_date,
		CAST(order_delivered_customer_date AS TIME) AS delivered_customer_time,
		
		CAST(order_estimated_delivery_date AS DATE) AS estimated_delivery
FROM staging_orders 
);

-- Bảng cô lập và báo cáo dữ liệu lỗi
CREATE OR REPLACE VIEW order_error AS (
	SELECT 
		-- Các khoá 
		order_id,
		customer_id,
		
		-- Phân loại 
		order_status,
		
		--- Nhóm thời gian
		
		-- Thời gian thanh toán 
		CAST(order_purchase_timestamps AS TIMESTAMP) AS purchase_timestamp,
		
		-- Thời gian xác nhận đơn
		CAST(order_approved_at AS TIMESTAMP) AS approved_at_timestamp,
		
		-- Thời gian đưa cho đơn vị vận chuyển
		CAST(order_delivered_carrier_date AS TIMESTAMP) AS delivered_carrier_timestamp,

		-- Thời gian khách hàng nhận được đơn hàng
		CAST(order_delivered_customer_date AS TIMESTAMP) AS delivered_customer_timestamp,

		-- Thời gian nhận hàng dự kiến
		CAST(order_estimated_delivery_date AS DATE) AS estimated_delivery
FROM staging_orders 
WHERE --- Logic vòng đời đơn hàng: Các lỗi  thời gian bị sai
	order_purchase_timestamps > order_approved_at OR
	order_approved_at > order_delivered_carrier_date OR
	order_delivered_carrier_date > order_delivered_customer_date 
)

--------------------------------- Bảng order items ---------------------------------
CREATE OR REPLACE VIEW order_items AS(
	SELECT
		-- Các khoá 
		order_id,
		product_id,
		seller_id,
		-- Độ đo
		CAST(order_item_id AS INT) AS item_quantity,
		CAST(price AS DECIMAL(10,2)) AS price,
		CAST(freight_value AS DECIMAL(10,2)) AS freight,
		CAST(shipping_limit_date AS TIMESTAMP) AS shipping_limit
	FROM staging_order_items
);
