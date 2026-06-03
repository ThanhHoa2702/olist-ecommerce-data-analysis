# Từ điển Dữ liệu: Dự án Phân tích Olist Brazil

**Nguồn dữ liệu:** Trích xuất từ công ty Olist (Sàn thương mại điện tử Brazil).

**Phạm vi tài liệu:** Gồm 5/9 bảng cốt lõi (Khách hàng, Đơn hàng, Vận chuyển sản phẩm,...).

**Mục tiêu:** Xác định nguồn thất thoát và hành vi mua sắm của khách hàng.

---

## 1. Bảng Customers

| Tên cột | Kiểu dữ liệu | Định nghĩa dữ liệu |
| :--- | :--- | :--- |
| `customer_id` | VARCHAR | [PK] Mã định danh cho từng lượt mua hàng. Mỗi mã gắn liền với một đơn hàng duy nhất. |
| `customer_unique_id` | VARCHAR | Mã định danh thực của khách hàng và có thể xuất hiện nhiều lần nếu mua nhiều đơn hàng. |
| `customer_zip_code_prefix` | VARCHAR | Mã bưu điện ở khu vực của Khách hàng. Ép kiểu VARCHAR để không mất số 0 ở đầu. |
| `customer_city` | VARCHAR | Tên Thành phố giao hàng. |
| `customer_state` | VARCHAR | Mã tiểu bang. |

---

## 2. Bảng Orders

| Tên cột | Kiểu dữ liệu | Định nghĩa dữ liệu |
| :--- | :--- | :--- |
| `order_id` | VARCHAR | [PK] Mã định danh đơn hàng. |
| `customer_id` | VARCHAR | [FK] Liên kết về bảng Customers. |
| `order_status` | VARCHAR | Trạng thái đơn hàng. |
| `order_purchase_timestamp` | TIMESTAMP | Thời gian Khách hàng đặt đơn. |
| `order_approved_at` | TIMESTAMP | Thời gian xác nhận đơn hàng. |
| `order_delivered_carrier_date`| TIMESTAMP | Thời gian đơn hàng đưa đi vận chuyển. |
| `order_delivered_customer_date`| TIMESTAMP | Thời gian khách hàng nhận được đơn. |
| `order_estimated_delivery_date`| TIMESTAMP | Thời gian giao hàng dự kiến. |

### Trường `order_status` (Bảng Orders)

* **Mô tả chung:** Ghi nhận trạng thái hiện tại của đơn hàng trong chuỗi cung ứng tại thời điểm dữ liệu được xuất khỏi hệ thống.
* **Kiểu dữ liệu (Data Type):** VARCHAR

**Cấu trúc vòng đời đơn hàng:**

| Trạng thái | Giai đoạn Vận hành |
| :--- | :--- |
| `created` | Đơn hàng được tạo trên hệ thống, hệ thống đang chờ khách hàng tiến hành thanh toán. |
| `approved` | Thanh toán đã được cổng thanh toán xác nhận thành công. |
| `invoiced` | Đã xuất hóa đơn, thông tin đơn hàng được chuyển về hệ thống. |
| `processing` | Đang tiến hành lấy hàng, đóng gói và chuẩn bị giao cho bưu cục. |
| `shipped` | Hàng đã rời kho nhà bán và được bàn giao cho đối tác vận chuyển thứ ba. |
| `delivered` | Đơn hàng đã được giao thành công đến tay. |
| `unavailable` | Hệ thống đánh dấu đơn hàng không thể thực hiện (thường do lỗi kho, hết hàng tồn kho đột xuất). |
| `canceled` | Đơn hàng bị hủy một cách chủ động (bởi khách hàng đổi ý hoặc không thể đáp ứng được nhu cầu khách hàng). |

> **NOTE:** Bản chất của `unavailable` và `canceled`: Mặc dù mang hai tên gọi khác nhau, nhưng về mặt luồng tiền cả hai trạng thái này đều dẫn đến kết quả: Công ty thất thu và phải hoàn tiền. Do đó, trong các DAX Measure, hai trạng thái này được gom nhóm để đo lường toàn diện Tổng đơn hàng thất thoát.

---

## 3. Bảng Order_items

| Tên cột | Kiểu dữ liệu | Định nghĩa dữ liệu |
| :--- | :--- | :--- |
| `order_id` | VARCHAR | [FK] Mã định danh đơn hàng. |
| `order_item_id` | INT | Số thứ tự món hàng trong đơn. |
| `product_id` | VARCHAR | [FK] Mã định danh sản phẩm. |
| `seller_id` | VARCHAR | Mã người bán hàng. |
| `shipping_limit_date` | TIMESTAMP | Thời hạn cho người bán hàng đóng gói và giao cho đơn vị vận chuyển. |
| `price` | DECIMAL | Giá trị sản phẩm. |
| `freight_value` | DECIMAL | Phí vận chuyển. |

---

## 4. Bảng Product

| Tên cột | Kiểu dữ liệu | Định nghĩa dữ liệu |
| :--- | :--- | :--- |
| `product_id` | VARCHAR | [PK] Mã định danh sản phẩm. |
| `product_category_name` | VARCHAR | [FK] Tên danh mục/ ngành hàng của sản phẩm viết bằng tiếng Brazil. |
| `product_name_lenght` | INT | Số lượng ký tự trong tên sản phẩm. |
| `product_description_lenght` | INT | Số lượng ký tự trong phần mô tả sản phẩm. |
| `product_photos_qty` | INT | Số lượng hình ảnh được người bán đăng tải cho sản phẩm này. |
| `product_weight_g` | FLOAT | Trọng lượng của sản phẩm (Đơn vị: Gram). |
| `product_length_cm` | FLOAT | Chiều dài của sản phẩm (Đơn vị: Centimet). |
| `product_height_cm` | FLOAT | Chiều cao của sản phẩm (Đơn vị: Centimet). |
| `product_width_cm` | FLOAT | Chiều rộng của sản phẩm (Đơn vị: Centimet). |

---

## 5. Bảng Product_category_name_translation

| Tên cột | Kiểu dữ liệu | Định nghĩa dữ liệu |
| :--- | :--- | :--- |
| `product_category_name` | VARCHAR | [PK] Tên danh mục bằng tiếng Bồ Đào Nha. |
| `product_category_name_english` | VARCHAR | Tên danh mục đã được dịch sang tiếng Anh. |

---

### 📝 Lưu ý hệ thống:
1. Bảng `Customers` được thiết kế theo dạng Phiên giao dịch. Do đó, `customer_id` được dùng làm Primary Key thay vì `customer_unique_id`.
2. Bảng `Order_items` được hoạt động một mã đơn hàng được lặp lại nhiều lần.
3. Toàn bộ dữ liệu theo tiếng Bồ Đào Nha, và bảng `Product_category_name_translation` sinh ra để chuyển tên danh mục sang tiếng Anh.
