
---------------------------------***** Đưa Data vào  môi trường kiểm thử *****---------------------------------

--------------------------------- Môi trường kiểm thử Bảng Customers ---------------------------------
CREATE TABLE Staging_Customers (
	customer_id VARCHAR(50),
	customer_unique_id VARCHAR(50),
	customer_zip_code_prefix VARCHAR(50),
	customer_city VARCHAR(50),
	customer_state VARCHAR(50)
);
--------------------------------- Môi trường kiểm thử Bảng orders ---------------------------------
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

--------------------------------- Môi trường kiểm thử Bảng order_items ---------------------------------

CREATE TABLE Staging_order_items (
	order_id VARCHAR(50),
	order_item_id VARCHAR(50),
	product_id VARCHAR(50),
	seller_id VARCHAR(50),
	shipping_limit_date VARCHAR(50),
	price VARCHAR(50),
	freight_value VARCHAR(50)
);

---------------------------------  Môi trường kiểm thử Bảng products ---------------------------------

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

--------------------------------- Môi trường kiểm thử Bảng product_category_name_Trans ---------------------------------
CREATE TABLE Staging_product_category_name_Trans (
	product_category_name VARCHAR(50),
	product_category_name_english VARCHAR(50)
);


---------------------------------****** KIỂM TRA CHẤT LƯỢNG DỮ LIỆU ******---------------------------------

--------------------------------- Bảng Customers  ---------------------------------

---- Kiểm tra dữ liệu trùng lắp

SELECT 
	COUNT(*) AS Total_customers,
	COUNT(DISTINCT customer_id) AS Unique_customer_id,
	COUNT(DISTINCT customer_unique_id) AS Unique_id
FROM Staging_Customers;

---- Kiểm tra giá trị NULL
SELECT
	COUNT(CASE WHEN customer_id IS NULL THEN 1 END) AS customer_id_NULL,
	COUNT(CASE WHEN customer_unique_id IS NULL THEN 1 END) AS unique_id_NULL,
	COUNT(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 END) AS zip_code_NULL,
	COUNT(CASE WHEN customer_city IS NULL THEN 1 END) AS city_NULL,
	COUNT(CASE WHEN customer_state IS NULL THEN 1 END) AS state_NULL
FROM Staging_Customers; -- Theo logic, chất lượng dữ liệu đều có thể sử dụng được, không bị lỗi.

--------------------------------- Bảng Orders  ---------------------------------

---- Tổng quan dữ liệu
SELECT * 
FROM Staging_Orders; 

--- Kiểm tra thời gian dữ liệu 
SELECT 
	MIN(order_purchase_timestamps),
	MAX(order_delivered_customer_date)
FROM staging_orders;

---- Kiểm tra giá trị trùng lặp
SELECT 
	COUNT(order_id) AS Total_order,
	COUNT(DISTINCT order_id) AS Unique_order_id,
	COUNT(DISTINCT customer_id) AS unique_customer_id
FROM staging_orders; -- Do dữ liệu hoạt động phiên giao dịch việc đếm customer_id, 
					 -- Unique_customer_id đảm bảo rằng mỗi mã đơn hàng đồng nghĩa 1 mã khách hàng trong bảng Orders.

---- Kiểm tra giá trị NULL 

SELECT	
	COUNT(CASE WHEN order_id IS NULL THEN 1 END) AS order_NULL,
	COUNT(CASE WHEN customer_id IS NULL THEN 1 END) AS customer_id_NULL,
	COUNT(CASE WHEN order_status IS NULL THEN 1 END) AS order_status_NULL,
	COUNT(CASE WHEN order_purchase_timestamps IS NULL THEN 1 END) purchase_NULL
FROM staging_orders; -- Kiểm tra giá trị trạng thái đơn hàng: Trạng thái đơn hàng NULL => Lỗi dữ liệu
					 -- Kiểm tra giá trị thanh toán khách hàng: Xuất hiện NULL ở thời gian khách hàng => Lỗi dữ liệu, hệ thống 

-- Kiểm tra logic định nghĩa trạng thái đơn hàng 

SELECT order_status
FROM Staging_Orders
GROUP BY order_status
ORDER BY order_status ASC; -- Có 8 trạng thái đơn hàng. Mỗi đơn hàng được ráng các trạng thái, mang ý nghĩa vòng đời dữ liệu khác nhau.
						   -- Trạng thái sẽ có những thuộc tính TIMESTAMPS khác nhau. Để kiểm tra logic dòng thời gian có bị lỗi hay không.
						   -- Dựa vào các trạng thái để suy ra những logic thời gian được phép trống hay không được phép trống.

-- 1) Trạng thái 'Đã duyệt thanh toán'
SELECT *
FROM staging_orders
WHERE order_status = 'approved' 
	AND (order_purchase_timestamps IS NULL OR -- 1. Lỗi: Không có thời gian tạo đơn 
		 order_approved_at IS NULL OR -- 2. Lỗi: Không  có thời gian xác nhận đơn
		 order_delivered_carrier_date IS NOT NULL OR -- 3. Lỗi: giao hàng 
		 order_delivered_customer_date IS NOT NULL); -- 4. Lỗi: nhận hàng
		 
-- 2) Trạng thái 'Huỷ đơn'
SELECT *
FROM staging_orders
WHERE order_status = 'canceled' 
	AND order_purchase_timestamps IS NULL; -- Lỗi không có thời gian đặt đơn nhưng lại trạng thái huỷ, 
										  -- Còn các mốc thời gian còn lại có thể trống, hoặc không trống.
		 
-- 3) Trạng thái 'Khởi tạo'
SELECT *
FROM staging_orders
WHERE order_status = 'created' 
	AND (order_purchase_timestamps IS NULL OR -- 1. Lỗi: Không có thời gian tạo đơn 
		 order_approved_at IS NOT NULL OR -- 2. Lỗi: Có thời gian xác nhận đơn nhưng không chuyển trạng thái
		 order_delivered_carrier_date IS NOT NULL OR -- 3.Lỗi: thời gian giao hàng
		 order_delivered_customer_date IS NOT NULL); -- 4. Lỗi: thời gian nhận hàng

-- 4) Trạng thái 'Đơn hàng thành công' kết thúc đơn hàng 
SELECT 
	*
FROM staging_orders
WHERE order_status = 'delivered' 
	AND (order_purchase_timestamps IS NULL OR -- 1. Lỗi: Không có thời gian tạo đơn
		 order_approved_at IS NULL OR -- 2. Lỗi: Không có thời gian xác nhận đơn
		 order_delivered_carrier_date IS NULL OR -- 3. Lỗi: Không có thời gian vận chuyển
		 order_delivered_customer_date IS NULL); -- 4. Lỗi: Không có thời gian khách nhận đơn nhưng chuyển trạng thái thành công.
	--- => Xuất hiện 23 đơn hàng bị lỗi về logic thời gian. 
-- Đếm các đơn hàng trong từng lỗi
SELECT 
	COUNT(CASE WHEN order_purchase_timestamps IS NULL THEN 1 END) AS Error1,
	COUNT(CASE WHEN order_approved_at IS NULL THEN 1 END) AS Error2, 
	COUNT(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 END) AS Error3,
	COUNT(CASE WHEN order_delivered_customer_date IS NULL THEN 1 END) AS Error4
FROM staging_orders
WHERE order_status = 'delivered'; -- Việc check lỗi này sẽ xem được lỗi của những đơn hàng trạng thái Delivered 
								-- Tuy nhiên có những đơn hàng nằm xuất hiện ở nhiều lỗi.
								-- Tuyệt đối không được cộng số lỗi lại với nhau => số lượng đơn hàng lỗi 

-- 5) Trạng thái 'Đã lập hoá đơn'
SELECT *
FROM staging_orders
WHERE order_status = 'invoiced' 
	AND (order_purchase_timestamps IS NULL OR -- 1. Lỗi: Không có thời gian tạo đơn
		 order_approved_at IS NULL OR -- 2. Lỗi: Không có thời gian xác nhận đơn 
		 order_delivered_carrier_date IS NOT NULL OR -- 3. Lỗi: Có thời gian giao hàng
		 order_delivered_customer_date IS NOT NULL); -- 4. Lỗi: Có thời gian nhận hàng

-- 6) Trạng thái 'Đang xử lý' chuẩn bị hàng cho vận chuyển
SELECT *
FROM staging_orders
WHERE order_status = 'processing' 
	AND (order_purchase_timestamps IS NULL OR -- 1. Lỗi: Không có thời gian tạo đơn
		 order_approved_at IS NULL OR -- 2. Lỗi: Không có thời gian xác nhận đơn 
		 order_delivered_carrier_date IS NOT NULL OR -- 3. Lỗi: Có thời gian giao hàng
		 order_delivered_customer_date IS NOT NULL); -- 4. Lỗi: Có thời gian nhận hàng
		 
-- 7) Trạng thái 'Đã vận chuyển' 
SELECT *
FROM staging_orders
WHERE order_status = 'shipped' 
	AND (order_purchase_timestamps IS NULL OR -- 1. Lỗi: Không có thời gian tạo đơn
		 order_approved_at IS NULL OR -- 2. Lỗi: Không có thời gian xác nhận đơn 
		 order_delivered_carrier_date IS NULL OR -- 3. Lỗi: Không thời gian giao hàng
		 order_delivered_customer_date IS NOT NULL); -- 4. Lỗi: Có thời gian nhận hàng
		 
-- 8) Trạng thái 'Không khả dụng'
SELECT *
FROM staging_orders
WHERE order_status = 'unavailable' 
	AND (order_purchase_timestamps IS NULL OR -- 1. Lỗi: Không có thời gian tạo đơn
		 order_approved_at IS NULL OR -- 2. Lỗi: Không có thời gian xác nhận đơn 
		 order_delivered_carrier_date IS NOT NULL OR -- 3. Lỗi: Có thời gian giao hàng
		 order_delivered_customer_date IS NOT NULL);  -- 4. Lỗi: Có thời gian nhận hàng

-- Kiểm tra những trạng thái đơn hàng nào bị sai logic thời gian
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
WHERE --- Logic vòng đời đơn hàng: Bắt các lỗi trình tự thời gian bị sai
	purchase > approved_at OR
	approved_at > delivered_carrier OR
	delivered_carrier > delivered_customer 
GROUP BY order_status; -- 1373 Đơn hàng giao thành công nhưng bị lỗi logic thời gian
					   -- 9 Đơn hàng đang trong quá trình giao 
					   -- => 1382 đơn hàng bị lỗi thời gian.

--------------------------------- Bảng Order items  ---------------------------------

-- Tổng quan dữ liệu 
SELECT *
FROM Staging_order_items;


-- Kiểm tra giá trị trùng lặp
SELECT 
	COUNT(*) AS Total_order_items,
	COUNT(DISTINCT order_id) AS Unique_id,
	COUNT(DISTINCT product_id) AS product_id,
	COUNT(DISTINCT seller_id) AS seller_id
FROM Staging_order_items; -- Mối quan hệ N - 1 với bảng orders.
						  -- Mỗi dòng có thể chứa các mã đơn hàng trùng lắp, và mã danh mục sản phẩm sẽ nằm trong 1 dòng.

---- Kiểm tra giá trị NULL
SELECT 
	COUNT(CASE WHEN order_id IS NULL THEN 1 END) AS order_id_NULL,
	COUNT(CASE WHEN order_item_id IS NULL THEN 1 END) AS order_item_id_error,
	COUNT(CASE WHEN product_id IS NULL THEN 1 END) AS product_id_NULL,
	COUNT(CASE WHEN seller_id IS NULL THEN 1 END) AS seller_id_NULL,
	COUNT(CASE WHEN shipping_limit_date IS NULL THEN 1 END) AS shipping_NULL,
	COUNT(CASE WHEN price IS NULL THEN 1 END) AS price_error,
	COUNT(CASE WHEN freight_value IS NULL THEN 1 END) AS freight_error
FROM Staging_order_items;

-- Kiểm tra các giá trị có bị lỗi hay không 
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

--------------------------------- Bảng products ---------------------------------

---- Tổng quan dữ liệu
SELECT *
FROM Staging_products

---- Kiểm tra giá trị trùng lặp
SELECT 
	COUNT(*) AS Total_product,
	COUNT(DISTINCT product_id) AS product_id,
	COUNT(DISTINCT product_category_name) AS category_name
FROM staging_products; -- Có 73 danh mục sản phẩm dựa theo dữ liệu 

---- Kiểm tra giá trị NULL
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
FROM staging_products; -- Xuất hiện 610 dòng dữ liệu bị NULL ở 4 cột, đại diện cho danh mục bị trống tên

---- Kiểm tra danh mục
SELECT product_category_name
FROM staging_products
GROUP BY product_category_name; -- Có 73 tên danh mục sản phẩm, 1 danh mục không có tên
								-- Tiến hành kiểm tra số lượng đơn của danh mục không tên ở bước sau 

--------------------------------- Bảng Product category name translation  ---------------------------------

---- Tổng quan dữ liệu 
SELECT * 
FROM staging_product_category_name_trans;

---- Kiểm tra giá trị trùng lặp
SELECT 
	COUNT(*) AS Total_name,
	COUNT(DISTINCT product_category_name) AS category_name,
	COUNT(DISTINCT product_category_name_english) AS category_name_E
FROM staging_product_category_name_trans; -- Ở bảng order items có 73 danh mục nhưng bảng translation chỉ có 71 danh mục được dịch sang tiếng Anh. 

---- Kiểm tra giá trị NULL
SELECT 
	COUNT(CASE WHEN product_category_name IS NULL THEN 1 END ) AS name_NULL,
	COUNT(CASE WHEN product_category_name_english IS NULL THEN 1 END ) AS name2_NULL
FROM staging_product_category_name_trans;

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




