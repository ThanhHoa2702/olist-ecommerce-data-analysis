
# Olist E-commerce Optimization: Decoding Canceled & Zombie Orders

## 📌 Overview

Xác định nguyên nhân thất thoát, giải quyết những vấn đề gây ảnh hưởng đến doanh thu, trải nghiệm khách hàng trong chuỗi cung ứng thương mại điện tử Olist: **Đơn hàng hủy** và **Đơn hàng treo**. Kết hợp phân tích định lượng và trực quan hóa dữ liệu, bóc tách các hành vi bất thường của khách hàng và xác định các điểm nghẽn logistics nhằm giảm thiểu tối đa thiệt hại về tài chính.

* **Gồm 2 trang Dashboard**: Executive Summary & Operations.
* **Công cụ sử dụng:** SQL (Data Cleaning & Exploration), Power BI (Data Modeling, DAX, Visualization).

## 📈 Key Insights & Business Impact

### Executive Summary 

* **Khám phá Đơn hàng:** 1.234 đơn hàng huỷ trên toàn hệ thống doanh thu cho tổng số đơn hàng này $95.24k, tỷ lệ huỷ đơn trong 2 năm là 1.24%. 
* **Nguyên nhân thất thoát:** 75 đơn hàng huỷ sau khi được đưa đi vận chuyển, gây thiệt hại chi phí vận chuyển $1,363k. Trọng điểm 2 ngành hàng Home & Furniture, Tech & Electronics có phí vận chuyển thất thoát cao.
* **Đơn huỷ:** Phát hiện 767 đơn hàng tồn tại trong hệ thống, trống thông tin sản phẩm. 386 đơn huỷ do chủ động của khách hàng nằm nhiều ở khâu Warehouse, có thể sự thay đổi về nhu cầu mua sắm sản phẩm của khách hàng.

**Kết luận:** Tỷ lệ đơn huỷ từ chủ động của khách hàng toàn ngành là 0.47% so với toàn hệ thống là 1.24%. Số lượng đơn huỷ gây ảnh hưởng trực tiếp đến trải nghiệm mua sắm nằm nhiều ở đơn hàng không khả dụng, hết sản phẩm nhưng vẫn treo trên hệ thống. Nhiều đơn hàng treo chưa cập nhật trạng thái tiềm ẩn có thể tiếp tục gây rò rỉ nguồn tiền ở khâu vận hành.

### Operations
* **Xử lý đơn hàng:** 1,721 đơn hàng treo chưa chuyển trạng thái,  615 đơn hàng chưa giao cho đơn vị vận chuyển, bị trễ hạn nghiêm trọng so với ngày dự kiến.
* **Vấn đề tiềm ẩn:** 1,106 đơn chiếm 64% Tổng đơn hàng treo đang bị kẹt ở trạng thái `shipped`. 
* **Rủi ro tài chính:** Tổng số đơn hàng đang giam giữ $272.85K doanh thu rủi ro và tiêu tốn $26.38K chi phí vận chuyển. Bang SP và RJ thành hai trọng điểm có số đơn bị treo nhiều nhất.

**Kết luận:** Theo biểu đồ Line không có sự tương quan của số lượng đơn với việc xử lý đơn. Việc lượng đơn hàng tăng trưởng mạnh theo thời gian, nhưng thời gian xử lý trung bình của đơn hàng không bị kéo dài. Và bên vận chuyển thứ ba cũng làm tốt. Có thể vấn đề nằm ở hệ thống, cần truy vết để nguồn tiền được xử lý. 

## 🚀 Recommendations
1. **Dữ liệu hệ thống:** Kiểm tra lại hệ thống dữ liệu thanh toán ở quá trình cập nhật trạng thái.
2. **Đối tác vận chuyển:** Liên hệ làm việc và tìm hiểu, giải trình về đơn hàng kẹt chặng `shipped` quá 30 ngày.
3. **Hệ thống Kho hàng:** Xử lý các đơn hàng kẹt ở Warehouse tối ưu hóa không gian tồn kho cho các ngành hàng.

---

## 🛠 Tech Stack & Skills Demonstrated
* **Truy vấn, làm sạch dữ liệu:** Bóc tách cấu trúc logic các trạng thái vòng đời của đơn hàng, xử lý danh mục sản phẩm không tên.
* **Mô hình hoá dữ liệu:** 2 Fact table, 3 Dimension tables.
* **Kỹ thuật phân tích:** Tối ưu Filter Context, Weighted Average Rate, Time-Intelligence.
* **Trực quan dữ liệu:** Chuẩn UX/UI.

## 🏗 Data Architecture & Data Cleaning

### Kỹ thuật & Giải pháp dọn dẹp
Trước khi đưa vào mô hình, dữ liệu thô gặp phải những vấn đề logic khiến khó khăn trong việc ra quyết định xử lý hay giữ lại những dòng dữ liệu và các thách thức về việc truy vấn những đơn hàng treo có nguy cơ tiếp tục ảnh hưởng đến doanh thu: 

* Bảng `fact_orders`:

<details>
<summary> 1,382 đơn hàng lỗi logic dòng thời gian. Trong đó có 1373 đơn hàng đã kết thúc vòng đời và đã được tính vào doanh thu. </summary>
	
```
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
GROUP BY order_status;
```
<img width="457" height="181" alt="image" src="https://github.com/user-attachments/assets/5feb47c1-20b4-438c-aaea-b1175356adfa" />

</details>

<details>
<summary> 23 đơn hàng delivered trống trong các cột mốc thời gian không hợp lý . </summary>
	
```
SELECT 
	*
FROM staging_orders
WHERE order_status = 'delivered' 
	AND (order_purchase_timestamps IS NULL OR -- 1. Lỗi: Không có thời gian tạo đơn
		 order_approved_at IS NULL OR -- 2. Lỗi: Không có thời gian xác nhận đơn
		 order_delivered_carrier_date IS NULL OR -- 3. Lỗi: Không có thời gian vận chuyển
		 order_delivered_customer_date IS NULL)
```
<img width="1944" height="323" alt="image" src="https://github.com/user-attachments/assets/a8a014ed-031a-4e0c-969d-c16c362bf0ec" />

</details>

<details>
<summary> NULL values: Các cột mốc thời gian của các đơn hàng bị trống thiếu dữ liệu trong thời gian quá lâu so với thời gian cập nhật dữ liệu. </summary>

```
SELECT
	o.order_status,
	COUNT(DISTINCT(o.order_id))
FROM orders AS o
LEFT JOIN order_items AS items
ON items.order_id = o.order_id
WHERE 
	------ Trạng thái những đơn hàng thuộc Warehouse
(	order_status IN ('approved','invoiced','processing')

	-- Vi phạm mốc thời gian: thời gian cập nhật dữ liệu cuối cùng vượt qua thời gian đưa cho đơn vị vận chuyển
	AND ((SELECT MAX(delivered_customer_timestamp) FROM orders) > items.shipping_limit)

	AND delivered_carrier_timestamp IS NULL) -- Chưa giao cho đơn vị vận chuyển 
OR
    ------ Trạng thái những đơn hàng thuộc Shipped
(	order_status = 'shipped'

	-- Vi phạm mốc thời gian: Thời gian cập nhật dữ liệu cuối cùng của hệ thống vượt qua thời gian dự kiến > 30 days
	AND (SELECT MAX(delivered_customer_date) FROM orders)::DATE - estimated_delivery::DATE > 30)

	AND delivered_customer_date IS NULL -- Khách chưa nhận được hàng 
GROUP BY o.order_status 
```
<img width="348" height="229" alt="image" src="https://github.com/user-attachments/assets/306cd998-507b-4bc5-938a-77609b962581" />


</details>

* Bảng `order_items`:

767 đơn hàng không có thông tin sản phẩm: Những mã đơn hàng `fact_orders` khách đã bấm đặt hàng, 603 đơn hàng `unavailable` và 164 đơn hàng `canceled`. Nhưng lại không có dữ liệu trong `order_items`.

<details>
	
<summary> Giá bán của danh mục sản phẩm khác nhau, không cố định giá. Phí vận chuyển cũng linh hoạt theo từng vùng, từng thành phố khác nhau. </summary>

```SQL
SELECT 
	prod.category_name,
	items.price,
	items.freight
FROM products AS prod
INNER JOIN order_items AS items
ON prod.product_id = items.product_id
GROUP BY items.price, prod.category_name,items.freight
ORDER BY prod.category_name
```
<img width="708" height="333" alt="image" src="https://github.com/user-attachments/assets/4a2581f3-ff90-453a-9283-fb9a86f0fc26" />
</details>

* Bảng `products`:

<details>
<summary> Danh mục đơn hàng NULL: 610 danh mục sản phẩm bị bỏ trống, tuy nhiên những đơn hàng này vẫn được xác nhận đơn và đã giao thành công đã được tính vào doanh thu tổng. </summary>

```SQL
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

```
<img width="432" height="254" alt="image" src="https://github.com/user-attachments/assets/f3ceefa9-12cc-42f3-afe3-362359501ec1" />

</details>
	
Việc đưa ra các quyết định cho những hành động dữ liệu rất quan trọng khi đưa dữ liệu lỗi vào sẽ khiến dòng thời gian bị sai lệch, hoặc nếu loại bỏ sẽ gây bốc hơi một lượng lớn nguồn doanh thu, làm sai lệch số liệu tồn kho. 

Mục tiêu của dự án: Truy vết về những vấn đề gây rò rỉ doanh thu.

Phương thức xử lý: Cô lập dữ liệu lỗi để không làm sai lệch các chỉ số tính toán thời gian, bắt buộc giữ lại nhằm bảo toàn bức tranh tổng doanh thu. Báo cáo trực quan những vấn đề có thể sẽ tiếp tục gây thêm thất thoát cho doanh thu.

## 📊 DAX Formula & Analytics Logic

### Sơ đồ Mô hình dữ liệu
Mô hình dữ liệu được chuẩn hóa theo dạng Star Schema để tối ưu hóa tốc độ truy vấn và xử lý:
* **Fact Table:** `fact_orders` thông tin trạng thái của đơn hàng và các cột mốc của vòng đời đơn hàng, `order_items` thông tin sản phẩm đơn hàng và tên sản phẩm, doanh thu, chi phí.
* **Dimension Tables:** `dim_customers`, `dim_products`, `dim_calendar`.

<details>
<summary> Data Model View </summary>
<img width="1481" height="1001" alt="image" src="https://github.com/user-attachments/assets/487b3c24-dc62-4c97-93fe-c3dcaa5bd9cd" />
</details>

Toàn bộ các chỉ số đo lường hiệu suất đều được tính toán bằng trung bình có trọng số, kiểm soát Filter Context chặt chẽ. Nhằm tránh các biểu đồ trực quan rơi vào việc cộng dồn tỷ lệ phần trăm.

**1. Tỷ lệ hủy đơn Toàn ngành hàng:**

* `Cancellation_Rate_by_Category` = $\frac{TotalCanceledCategory}{TotalOrderbyCategory}$

Độ đo này khác với Tỷ lệ huỷ đơn toàn hệ thống,`Total_Canceled_Category` điều kiện của tử số này đã được ghi nhận cả 2 bảng `fact_orders` và `order_items` thời gian đặt hàng, thông tin sản phẩm, ngành hàng khác với `Cancellation_Rate %` trên toàn hệ thống sẽ có những đơn hàng được huỷ trước khi hệ thống ghi nhận nghĩa là sẽ không có dữ liệu bên bảng `order_items`.

Mẫu số là `Total_Order_by_Category` có điều kiện lọc cố định ngành hàng cụ thể và có thông tin xác nhận trong `order_items` nhằm tối ưu ngữ cảnh khi trực quan.

<details>
<summary>DAX Query : </summary>
	
```
VAR Total_Canceled_Category =
    CALCULATE(DISTINCTCOUNT(fact_orders[order_id]),
    -- Điều kiện 1: Thuộc trạng thái đơn hàng
    fact_orders[order_status] = "canceled",
    -- Điều kiện 2: Lấy những đơn hàng có thông tin
    FILTER(fact_orders,NOT ISEMPTY(RELATEDTABLE(order_items))))
VAR Total_Order_by_Category = 
	CALCULATE( 
		DISTINCTCOUNT(fact_orders[order_id]),
		 -- Điều kiện: Lấy những đơn hàng có thông tin
		FILTER(fact_orders,NOT ISEMPTY(RELATEDTABLE(order_items)))
        -- Bộ lọc cốt lõi nhằm tính tỷ trọng của các ngành hàng cụ thể
		ALLEXCEPT(dim_products, 
             dim_products[Macro_Category],
		     dim_products[category_name_eng] )
		  ) -- ALLEXCEPT cố định mẫu số, giúp tỷ lẹ phân bố chính xác theo từng ngành
RETURN 
    DIVIDE(Total_Canceled_Category, Total_Order_by_Category,0)
```
**Tương tác chéo:** Sử dụng giải pháp `ALLEXCEPT` để cố định mẫu số quy mô khi người xem click vào các phân đoạn lỗi, giúp tỷ lệ lỗi phân bổ chính xác theo từng ngành hàng.
</details>

<img width="925" height="401" alt="image" src="https://github.com/user-attachments/assets/9d4e6eb7-6d96-42e6-957f-cc3d7da42f1e" />


**2. Trạng thái của những đơn hàng treo:** 

Các đơn hàng treo nằm rải rác đều ở các khâu ở vòng đời đơn hàng và theo mục tiêu ban đầu, sẽ tập trung vào những đơn treo trong các khâu có thể sẽ gây ảnh hưởng đến nguồn tiền sau này (Những đơn đã được thanh toán nhưng chưa xử lý xong, chưa giao đi vận chuyển và những đơn hàng đã được giao đi vận chuyển nhưng vẫn chưa đến tay khách hàng).

Vấn đề xử lý và tạo các thước đo để tính tổng các đơn hàng theo trạng thái đơn hàng rất phức tạp vì về các vấn đề trạng thái đơn hàng sẽ có những logic thời gian khác nhau. 

Giải pháp: Tiến hành phân bố những đơn hàng treo theo vòng đời của đơn hàng, lấy cột mốc thời gian là ngày cập nhật cuối cùng của dữ liệu làm giới hạn.

Warehouse (`approved`,`invoiced`,`processing`), Shipping (`shipped`)

<details>
<summary>DAX Query : </summary>

```dax
WareHouse = 
VAR End_date = CALCULATE(MAX(fact_orders[delivered_customer_date]),ALL(fact_orders))
RETURN 
    CALCULATE(DISTINCTCOUNT(fact_orders[order_id]),
    -- Điều kiện lọc: Trạng thái đơn hàng trong WareHouse
    KEEPFILTERS(fact_orders[order_status] IN {"approved","invoiced","processing"}),
    -- Điều kiện lọc: Vi pham thời gian 
    End_date > order_items[shipping_limit],
    -- Điều kiện lọc: Chưa đưa hàng cho đơn vị vận chuyển
    ISBLANK(fact_orders[delivered_carrier_date]))
```
	
```dax
Total_Shipping_status = 
VAR End_date = CALCULATE(MAX(fact_orders[delivered_customer_date]),ALL(fact_orders))
RETURN
    CALCULATE(DISTINCTCOUNT(fact_orders[order_id]),
    -- Điều kiện lọc: 
    KEEPFILTERS(fact_orders[order_status] = "shipped"),
    -- Điều kiện những đơn hàng đang bị treo
    DATEDIFF(fact_orders[estimated_delivery],End_date,DAY) > 30,
    -- Điều kiện đơn hàng khách chưa nhận được hàng
    ISBLANK(fact_orders[delivered_customer_date])
    )
```
</details> 

<img width="900" height="405" alt="image" src="https://github.com/user-attachments/assets/95e72103-7dc0-46ee-99b9-88725fb89124" />


**3. Thời gian vận chuyển trung bình của đơn hàng**

Độ đo này được tính dựa trên trung bình tổng khoảng cách của ngày vận chuyển và ngày nhận đơn. Điều kiện tiên quyết những đơn hàng đã được giao thành công, dòng thời gian phải hợp lệ. Do vậy ta sẽ cô lập dữ liệu và tính những đơn hàng có logic thời gian hợp lệ nhất. 

<details>
<summary>DAX Query : </summary>
	
```
AVG_Shipped_day = 
    CALCULATE(
        AVERAGEX(fact_orders,DATEDIFF(fact_orders[delivered_carrier_date],fact_orders[delivered_customer_date],DAY)),
        -- 1.Điều kiện lọc: Trạng thái đơn hàng
        fact_orders[order_status] = "delivered",
        -- 2.Điều kiện lọc: Vòng đời đơn hàng hợp lệ
        NOT ISBLANK(fact_orders[delivered_carrier_date]),
        NOT ISBLANK(fact_orders[delivered_customer_date]),
        -- 3.Điều kiện lọc: Những ngày lỗi 
        DATEDIFF(fact_orders[delivered_carrier_date],fact_orders[delivered_customer_date],DAY) >= 0,
        -- 4.Điều kiện lọc: Ngày nhận hàng sẽ bé hơn ngày giao hàng dự kiến 
        fact_orders[delivered_customer_date] <= fact_orders[estimated_delivery]
    )
```
</details>

---
## Review

Đây là dự án học thuật, bộ dữ liệu thoả mãn mục địch ứng dụng những kiến thức cơ bản trong thống kê mô tả, truy vấn những vấn đề xuất hiện trong bộ dữ liệu. Mang tính chất tham khảo, không áp dụng hoặc sử dụng chỉ ra những vấn đề thực tế.

Cảm ơn Công ty Olist đã cung cấp dataset: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
