
# Olist E-commerce Optimization: Decoding Canceled & Zombie Orders

## 📌 Project Overview
Project nhằm xác định nguyên nhân thất thoát, giải quyết những vấn đề lớn có thể tiếp tục gây ảnh hưởng đến doanh thu trong chuỗi cung ứng và vận hành của nền tảng thương mại điện tử Olist (Brazil): **Đơn hàng hủy** và **Đơn hàng treo**. Bằng cách kết hợp tư duy phân tích định lượng và trực quan hóa dữ liệu, dự án bóc tách các luồng hành vi bất thường của khách hàng và xác định các điểm nghẽn logistics nhằm giảm thiểu tối đa thiệt hại về tài chính.

* **Trạng thái dự án:** Đã hoàn thành (Gồm 2 trang Dashboard: Executive Summary & Operations).
* **Công cụ sử dụng:** SQL (Data Cleaning & Exploration), Power BI (Data Modeling, DAX, Visualization).

---

## 🛠 Tech Stack & Skills Demonstrated
* **Data Querying & Cleaning:** SQL (Bóc tách cấu trúc logic các trạng thái vòng đời của đơn hàng, xử lý danh mục sản phẩm không tên).
* **Data Modeling:** Star Schema (2 Fact table, 3 Dimension tables).
* **Advanced Analytics:** DAX (Tối ưu Filter Context, Weighted Average Rate, Time-Intelligence).
* **Data Storytelling:** Trực quan hóa dữ liệu chuẩn UI/UX.

---

## 🏗 Data Architecture & Data Cleaning (SQL)

### 1. Sơ đồ Mô hình dữ liệu (Data Model)
Mô hình dữ liệu được chuẩn hóa theo dạng Star Schema để tối ưu hóa tốc độ truy vấn và xử lý Filter Context trong Power BI:
* **Fact Table:** `fact_orders` (Chứa thông tin trạng thái của đơn hàng và các cột mốc của vòng đời đơn hàng), `order_items` (Chứa thông tin sản phẩm đơn hàng và tên sản phẩm, doanh thu, chi phí).
* **Dimension Tables:** `dim_customers`, `dim_products`, `dim_calendar`.

### 2. Thách thức kỹ thuật & Giải pháp dọn dẹp (SQL Scripts)
Trước khi đưa vào mô hình, dữ liệu thô gặp phải những vấn đề logic khiến khó khăn trong việc ra quyết định xử lý hay giữ lại những dòng dữ liệu và các thách thức về việc truy vấn những dữ liệu khi mối quan hệ của các bảng phức tạp: 

Bảng `fact_orders`:
* **1,382 đơn hàng lỗi logic dòng thời gian** Trong đó có 1373 đơn hàng đã kết thúc vòng đời và đã được tính vào doanh thu.

* **Khoảng trống (NULL values):** Các cột mốc thời gian của các đơn hàng bị trống thiếu dữ liệu, phản ánh trạng thái dở dang của vận hành (Đơn bị hủy giữa chừng hoặc đơn bị kẹt hệ thống). 23 đơn hàng `delivered` bị NULL trong các cột mốc thời gian (Hệ thống vận hành đang có vấn đề).

Bảng `order_items`:
* **767 đơn hàng không có thông tin sản phẩm:** 767 đơn hàng này nằm ở bảng `fact_orders` khách đã bấm đặt hàng, 603 đơn hàng `unavailable` và 164 đơn hàng `canceled`. Nhưng lại không có thông tin trong `order_items`.
* Giá bán của các sản phẩm khác nhau theo từng ngày, không cố định giá sản phẩm. Việc truy vấn đơn giá trong các ngành hàng, danh mục sản phẩm chỉ lấy giá trung bình hoặc giá cao nhất bán vào thời điểm nào.
* Phí vận chuyển cũng linh hoạt theo từng vùng, từng thành phố khác nhau.

Bảng `products`:
* **Danh mục đơn hàng NULL**: 610 danh mục sản phẩm bị bỏ trống, tuy nhiên những đơn hàng này vẫn được xác nhận đơn và đã giao thành công đã được tính vào doanh thu tổng.

Việc đưa ra các quyết định cho những hành động dữ liệu rất quan trọng khi đưa dữ liệu lỗi vào sẽ khiến dòng thời gian bị sai lệch, hoặc nếu loại bỏ sẽ gây bốc hơi một lượng lớn nguồn doanh thu, làm sai lệch số liệu tồn kho. 

Mục tiêu của dự án: truy vết về những vấn đề gây rò rỉ doanh thu, vì vậy phương thức xử lý: Cô lập dữ liệu lỗi để không làm sai lệch các chỉ số tính toán thời gian, nhưng bắt buộc phải giữ lại để bảo toàn bức tranh tổng doanh thu.

## 📊 Advanced DAX Formula & Analytics Logic

Để báo cáo không rơi vào việc cộng dồn tỷ lệ phần trăm một cách cơ học, toàn bộ các chỉ số đo lường hiệu suất đều được tính toán bằng trung bình có trọng số  thông qua việc kiểm soát Filter Context chặt chẽ.

**Các độ đo thách thức** 

**1. Tỷ lệ Hủy đơn Thực tế (Toàn ngành hàng):**
Về độ đo này sẽ khác với Tỷ lệ huỷ đơn toàn hệ thống, chỉ tính những đơn hàng đã được ghi nhận và có thông tin về `product_id` trong bảng `orders_items` khác với toàn hệ thống sẽ có những đơn hàng được huỷ trước khi hệ thống ghi nhận (Không có dữ liệu ở bảng `orders_items`).

Công thức tổng quát về độ đo:
    
Cancellation_Rate_by_Category = $\frac{TotalCanceledCategory}{TotalOrderbyCategory}$

```
VAR Total_Canceled_Category =
    CALCULATE(DISTINCTCOUNT(fact_orders[order_id]),
    -- Điều kiện 1: Thuộc trạng thái đơn hàng
    fact_orders[order_status] IN {"canceled","unavailable"},
    -- Điều kiện 2: Lấy những đơn hàng có thông tin
    FILTER(fact_orders,NOT ISEMPTY(RELATEDTABLE(order_items))))
VAR Total_Order_by_Category = 
	CALCULATE( 
		DISTINCTCOUNT(fact_orders[order_id]),
        -- Bộ lọc cốt lõi nhằm tính tỷ trọng của các ngành hàng cụ thể
		ALLEXCEPT(dim_products, 
             dim_products[Macro_Category],
		     dim_products[category_name_eng] )
		  ) 
RETURN 
    DIVIDE(Total_Canceled_Category, Total_Order_by_Category,0)
```


* **Giải cứu Mẫu số khi tương tác chéo (Cross-filtering Protection):** Sử dụng giải pháp `ALLEXCEPT` và `REMOVEFILTERS` để cố định mẫu số quy mô khi người xem click vào các phân đoạn lỗi trên biểu đồ Bar Chart, giúp tỷ lệ lỗi phân bổ chính xác theo từng ngành hàng mà không bị biến thành `100%` đồng loạt.

**2. Trạng thái của những đơn hàng treo:** 
Các đơn hàng treo nằm rải rác đều ở các khâu ở vòng đời đơn hàng và theo mục tiêu ban đầu, sẽ tập trung vào những đơn treo trong các khâu có thể sẽ gây ảnh hưởng đến nguồn tiền sau này (Những đơn đã được thanh toán nhưng chưa xử lý xong, chưa giao đi vận chuyển và những đơn hàng đã được giao đi vận chuyển nhưng vẫn chưa đến tay khách hàng).

Vấn đề xử lý và tạo các thước đo để tính tổng các đơn hàng theo trạng thái đơn hàng rất phức tạp vì về các vấn đề trạng thái đơn hàng sẽ có những logic thời gian khác nhau. 

Giải pháp: Tiến hành phân bố những đơn hàng treo theo vòng đời của đơn hàng, lấy cột mốc thời gian là ngày cập nhật cuối cùng của dữ liệu làm giới hạn.

<details>
<summary><b>🛠️ Click để xem chi tiết Code DAX: Tỷ lệ Hủy đơn Thực tế</b></summary>

Vấn đề xử lý và tạo các thước đo để tính tổng các đơn hàng theo trạng thái đơn hàng rất phức tạp vì về các vấn đề trạng thái đơn hàng sẽ có những logic thời gian khác nhau. 

Giải pháp: Tiến hành phân bố những đơn hàng treo theo vòng đời của đơn hàng, lấy cột mốc thời gian là ngày cập nhật cuối cùng của dữ liệu làm giới hạn.
<details>

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

* Shipping (`shipped`)
```
Total_Shipping_status = 
VAR End_date = CALCULATE(MAX(fact_orders[delivered_customer_date]),ALL(fact_orders))
RETURN
    CALCULATE(DISTINCTCOUNT(fact_orders[order_id]),
    -- Điều kiện lọc: 
    fact_orders[order_status] = "shipped",
    -- Điều kiện những đơn hàng đang bị treo
    DATEDIFF(fact_orders[estimated_delivery],End_date,DAY) > 30,
    -- Điều kiện đơn hàng khách chưa nhận được hàng
    ISBLANK(fact_orders[delivered_customer_date])
    )
```
**3. Thời gian vận chuyển trung bình của đơn hàng**

Độ đo này được tính dựa trên trung bình tổng khoảng cách của ngày vận chuyển và ngày nhận đơn. Điều kiện tiên quyết những đơn hàng đã được giao thành công, dòng thời gian phải hợp lệ. Do vậy ta sẽ cô lập dữ liệu và tính những đơn hàng có logic thời gian hợp lệ nhất.

```
AVG_Shipped_day = 
    CALCULATE(
        AVERAGEX(fact_orders,DATEDIFF(fact_orders[delivered_carrier_date],fact_orders[delivered_customer_date],DAY)),
        -- Điều kiện lọc: ngày xác nhận đơn không được trống
        fact_orders[order_status] = "delivered",
        NOT ISBLANK(fact_orders[approved_at_date]),
        -- Điều kiện lọc: ngày giao cho đơn vị vận chuyển không được trống
        NOT ISBLANK(fact_orders[delivered_carrier_date]),
        NOT ISBLANK(fact_orders[delivered_customer_date]),
        -- Điều kiện lọc: Những ngày lỗi 
        DATEDIFF(fact_orders[delivered_carrier_date],fact_orders[delivered_customer_date],DAY) >= 0,
        -- Diều kiện lọc: Ngày nhận hàng sẽ bé hơn ngày giao hàng dự kiến 
        fact_orders[delivered_customer_date] <= fact_orders[estimated_delivery]
    )
```

---

## 📈 Key Insights & Business Impact

### Trang 1: Executive Summary (Bóc tách Đơn hàng Hủy)
* **Khám phá Đơn hàng Mồ côi:** Phát hiện **767 đơn hàng** tồn tại trong hệ thống nhưng hoàn toàn trống thông tin sản phẩm (`No item info`). Nghiên cứu luồng thời gian chứng minh đây là các trường hợp khách hàng hủy đơn ngay lập tức (Instant Cancellation) sau khi thanh toán, khiến hệ thống kho chưa kịp gán mã hàng.
* **Nút thắt Before Shipping:** Chiếm tỷ trọng lớn nhất trong luồng hủy đơn với **1,018 đơn hàng**. Đây là vùng cơ hội lớn nhất để tối ưu hóa quy trình xác nhận đơn.

### Trang 2: Operations Deep-Dive (Truy vết Đơn hàng Treo - Zombie)
* **Định vị Đơn Zombie:** Xác định **1,723 đơn hàng** ở trạng thái "Sống không qua khỏi, chết không xong" (Bị trễ hạn nghiêm trọng so với ngày dự kiến giao nhưng trạng thái không chuyển sang Delivered hay Canceled).
* **Nút thắt cổ chai Vận chuyển (3PL):** **64% đơn hàng Zombie** (1,106 đơn) đang bị kẹt ở trạng thái `shipped`. Điều này chỉ điểm trực diện năng lực yếu kém hoặc sự thiếu minh bạch của các đối tác vận chuyển thứ ba.
* **Rủi ro tài chính:** Đống đơn hàng Zombie này đang giam giữ **$272.85K doanh thu rủi ro** (Revenue at Risk) và tiêu tốn **$26.38K chi phí chìm** (Bao bì, nhân công đóng gói, vận chuyển chặng đầu). Biến bang **SP** và **RJ** thành hai điểm đen logistics cần xử lý khẩn cấp.

---

## 🚀 Actionable Recommendations (Khuyến nghị hành động)
1. **Kiểm toán Đối tác Vận chuyển (3PL Audit):** Trực tiếp làm việc và siết chặt KPI đối với các đơn vị vận chuyển tại bang SP và RJ, yêu cầu giải trình về 1,106 đơn hàng kẹt chặng `shipped` quá 90 ngày.
2. **Khắc phục Toàn vẹn dữ liệu API:** Kiểm tra lại kết nối API giữa hệ thống thanh toán và hệ thống kho để dứt điểm tình trạng đơn hàng mồ côi không có thông tin sản phẩm.
3. **Giải phóng Kho hàng:** Xử lý dứt điểm 301 đơn hàng đang kẹt ở khâu `processing` nội bộ kho để tối ưu hóa không gian tồn kho cho các ngành hàng có biên lợi nhuận cao như *Toys & Baby* hay *Health & Beauty*.
