# NHÀ CANH – bản chạy nhanh (ESP32-S3 + Android)

Code viết theo file "dự án thi KHKT cho HS cấp 2". Gồm 2 phần:

| Phần | File | Việc làm |
|---|---|---|
| Firmware | `esp32/nha_canh.ino` | Đọc MQ-2, DHT22, DS18B20, PIR, mực nước, âm thanh, quang, dò line, MPU6050; mở `http://<IP>/api` trả JSON |
| App Android | `android/MainActivity.kt` | Gọi `/api` mỗi 2 giây, hiển thị số liệu, cảnh báo, nhật ký, mở camera điện thoại |

## Chạy firmware
1. Arduino IDE → board **ESP32S3 Dev Module**; cài thư viện: *DHT sensor library*, *Adafruit Unified Sensor*, *OneWire*, *DallasTemperature*.
2. Sửa `WIFI_SSID`, `WIFI_PASS`, nạp code, mở Serial Monitor (115200) để xem **IP**.
3. Thử: mở `http://<IP>/api` trên trình duyệt (điện thoại và ESP32 cùng Wi-Fi).

## Chạy app
1. Android Studio → New Project → **Empty Activity** (Compose), package `com.example.nhacanh` (hoặc đổi dòng `package`).
2. Thay nội dung `MainActivity.kt` bằng file trong repo.
3. `AndroidManifest.xml`: thêm trước thẻ `<application`:
   `<uses-permission android:name="android.permission.INTERNET" />`
   và trong thẻ `<application` thêm `android:usesCleartextTraffic="true"` (vì ESP32 dùng http).
4. Chạy. App mở sẵn **chế độ mô phỏng** để xem giao diện; tắt công tắc, nhập IP ESP32 để dùng dữ liệu thật.

## Lưu ý quan trọng
- Chân GPIO là bảng **dự kiến** của tài liệu; kiểm tra board thật. Chân OUT/AO 5 V (MQ-2 AO, PIR...) phải chia áp/chuyển mức, **không nối thẳng vào ESP32-S3**.
- MQ-2 chỉ báo *tín hiệu* khói/khí dễ cháy (số ADC, không phải ppm CO). Ngưỡng ở đầu `MainActivity.kt` là giá trị tạm, phải chỉnh theo đo thực tế.
- Cực tính module âm thanh/quang/dò line tuỳ loại (HIGH hay LOW là "có"): app đang hiển thị giá trị thô.
- Không thay thế thiết bị báo cháy/CO đạt chuẩn. Không thử MQ-2 bằng cách đốt hay xả gas.
- Chưa có thông báo đẩy (notification) và biểu đồ lịch sử; cảnh báo hiện trên màn hình và trong nhật ký. Code chưa được biên dịch/chạy thử trên máy thật.
