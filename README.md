
# Olist E-commerce Optimization: Decoding Canceled & Zombie Orders

## 📌 Project Overview
Project nhằm xác định nguyên nhân thất thoát, giải quyết những vấn đề lớn có thể tiếp tục gây ảnh hưởng đến doanh thu trong chuỗi cung ứng và vận hành của nền tảng thương mại điện tử Olist (Brazil): **Đơn hàng hủy (Canceled Orders)** và **Đơn hàng treo (Zombie Orders)**. Bằng cách kết hợp tư duy phân tích định lượng và trực quan hóa dữ liệu, dự án bóc tách các luồng hành vi bất thường của khách hàng và xác định chính xác các điểm nghẽn logistics nhằm giảm thiểu tối đa thiệt hại về tài chính.

* **Trạng thái dự án:** Đã hoàn thành (Gồm 2 trang Dashboard: Executive Summary & Operations).
* **Công cụ sử dụng:** SQL (Data Cleaning & Exploration), Power BI (Data Modeling, DAX, Visualization).

---

## 🛠 Tech Stack & Skills Demonstrated
* **Data Querying & Cleaning:** SQL (Dọn dẹp logic dòng thời gian, bóc tách cấu trúc logic dữ liệu).
* **Data Modeling:** Star Schema (2 Fact table, 3 Dimension tables).
* **Advanced Analytics:** DAX (Tối ưu Filter Context, Weighted Average Rate, Time-Intelligence).
* **Data Storytelling:** Trực quan hóa dữ liệu chuẩn UI/UX, tối ưu tỷ lệ Data-Ink Ratio.

---

## 🏗 Data Architecture & Data Cleaning (SQL)

### 1. Sơ đồ Mô hình dữ liệu (Data Model)
Mô hình dữ liệu được chuẩn hóa theo dạng **Sơ đồ ngôi sao (Star Schema)** để tối ưu hóa tốc độ truy vấn và xử lý Filter Context trong Power BI:
* **Fact Table:** `fact_orders` (Chứa thông tin trạng thái của đơn hàng và các cột mốc của vòng đời đơn hàng `timestamp`), `order_items` (Chứa thông tin sản phẩm đơn hàng và tên sản phẩm, doanh thu, chi phí).
* **Dimension Tables:** `dim_customers`, `dim_products`, `dim_calendar`.

### 2. Thách thức kỹ thuật & Giải pháp dọn dẹp (SQL Scripts)
Trước khi đưa vào mô hình, dữ liệu thô gặp phải những lỗi logic nghiêm trọng về mặt thời gian: 
  1. **1,382 đơn hàng lỗi logic dòng thời gian** Trong đó có 1373 đơn hàng đã kết thúc vòng đời và đã được tính vào doanh thu.
* **Giữ lại những đơn hàng lỗi về logic thời gian** Việc đưa ra quyết định này rất quan trọng vì khi đưa dữ liệu lỗi vào tính những mốc thời gian sẽ khiến dòng thời gian bị sai lệch, mà nếu loại bỏ sẽ gây những hậu quả về nguồn doanh thu, tồn kho. Vì mục tiêu và vấn đề phân tích khi tiến hành trực quan những timeline thì ta sẽ đặt điều kiện lọc những đơn hàng có dòng thời gian hợp lệ.
* **Xử lý khoảng trống (Handling NULL values):** Bảm chất các cột mốc thời gian của các đơn hàng bị trống không phải là thiếu dữ liệu, mà là phản ánh trạng thái dở dang của vận hành (Đơn bị hủy giữa chừng hoặc đơn bị kẹt hệ thống) vì vậy sẽ giữ nguyên.
*  2. **Xuất hiện về việc thiếu dữ liệu** của 2 bảng Products và Product_category_name_translation. 
* **Xử lý danh mục đơn hàng NULL**: Tiến hành truy vấn phát hiện 610 đơn hàng không có danh mục sản phẩm, tuy nhiên dựa trên nguyên lý hoạt động của hệ thống Olist thì những đơn hàng thuộc trạng thái 

## 📊 Advanced DAX Formula & Analytics Logic

Để báo cáo không rơi vào "Cái bẫy Excel" (cộng dồn tỷ lệ phần trăm một cách cơ học), toàn bộ các chỉ số đo lường hiệu suất đều được tính toán bằng trung bình có trọng số (Weighted Average) thông qua việc kiểm soát Filter Context chặt chẽ.

* **Tỷ lệ Hủy đơn Thực tế (Toàn hệ thống):**
    ```dax
    Cancellation_Rate_True = 
    DIVIDE(
        [Total canceled], 
        [Total Orders], 
        0
    )
    ```
    *Logic:* Đảm bảo dòng `Total` dưới cùng của bảng Matrix tính toán lại trên bình diện toàn cục (Tổng tử số chia tổng mẫu số) thay vì cộng tổng các tỷ lệ thành phần.

* **Giải cứu Mẫu số khi tương tác chéo (Cross-filtering Protection):**
    Sử dụng giải pháp cấu hình `ALLEXCEPT` và `REMOVEFILTERS` để cố định mẫu số quy mô khi người dùng click vào các phân đoạn lỗi trên biểu đồ Bar Chart, giúp tỷ lệ lỗi phân bổ chính xác theo từng ngành hàng mà không bị biến thành `100%` đồng loạt.

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
