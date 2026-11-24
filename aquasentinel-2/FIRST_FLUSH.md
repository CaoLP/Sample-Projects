# Cửa Xả Thông Minh: giữ nước mưa đợt đầu tại cửa xả ven biển

Bản cũ dùng van bi nhựa + servo + bể lọc cát sỏi. Cách đó chỉ hợp với ống nhỏ. Cửa xả ven biển Đà Nẵng là cống hộp lớn, lưu lượng khi mưa rất lớn, không lọc qua bể cát được. Bản mới bám vào hạ tầng thành phố đang có.

## Vấn đề thực tế
- Nhiều khu vẫn là **cống chung** (nước mưa + nước thải sinh hoạt).
- Trời khô: **đập tràn trong giếng tách dòng** dẫn nước thải vào **cống bao** → trạm bơm → nhà máy xử lý nước thải.
- Mưa lớn: nước vượt đập tràn chảy thẳng ra biển. **Đợt đầu** cuốn bùn thải đọng trong cống nên nước ra biển đen và hôi.
- Báo chí ghi nhận nước thải vẫn tràn ra biển sau mưa lớn, trạm bơm có lúc không kịp.

## Giải pháp
Gắn 1 hộp cảm biến + điều khiển tại giếng tách dòng của mỗi cửa xả:

| Chế độ | Khi nào | Cửa phai ra biển | Bơm vào cống bao |
|---|---|---|---|
| DRY | Trời khô | Đóng | Tắt (nước tự chảy qua đập tràn) |
| HOLD | Mưa ≥ 1mm/10 phút | **Đóng**, giữ nước đợt đầu | **Bật** |
| RELEASE | Đã giữ ≥ 10 phút **và** nước đã trong, hoặc đã quá 30 phút | Mở | Tắt |
| FLOOD | Nước trong giếng ≥ 120cm | **Mở ngay** | Tắt |

- **Chống ngập luôn ưu tiên hơn chống ô nhiễm.** Không được giữ nước làm ngập phố.
- Server AquaSentinel nhận dữ liệu qua LoRa. Kết hợp dự báo mưa thì có thể **bơm hút cạn giếng và cống trước cơn mưa** để có chỗ chứa đợt đầu.
- Ngoài thực tế: hộp chỉ **gửi khuyến nghị** cho đơn vị vận hành thoát nước (hoặc điều khiển cửa phai điện nếu được cho phép). Học sinh không tự can thiệp vào cửa xả thật.

## Mô hình demo
- Hộp mica chia 3 ngăn: **cống chung** → **giếng tách dòng** (đập tràn thấp) → 2 lối ra: "biển" (khay xanh) và "cống bao" (bình nhựa).
- Cửa phai = tấm mica trượt, kéo bằng servo MG996R. Bơm 12V mini qua relay.
- Diễn: đổ nước pha cà phê (bùn thải) rồi tưới nước sạch (mưa). Khay "biển" chỉ nhận nước trong. Đổ nhanh cho nước dâng thì cửa tự mở (chống ngập).
- Đo trước/sau: độ đục và TDS ở khay biển khi có và không có hệ thống.

## Linh kiện (mỗi cửa xả, bản mô hình)
| Linh kiện | Ghi chú | Giá tham khảo |
|---|---|---|
| ESP32 + LoRa SX1276 923MHz | dùng chung kiểu với hộp cột | ~250k |
| Cảm biến mưa tipping bucket | thay cảm biến mưa tấm (chỉ biết có/không mưa) | ~250k |
| Cảm biến độ đục SEN0189 | ra 0–4.5V, phải qua phân áp 10k/20k | ~120k |
| JSN-SR04T | đo mực nước trong giếng | ~120k |
| Servo MG996R + mica | cửa phai | ~120k |
| Bơm 12V mini + relay | | ~100k |

## Đấu nối
| Module | Nối tới ESP32 |
|---|---|
| Tipping bucket (2 dây công tắc) | GPIO34 và GND, thêm điện trở 10k kéo lên 3V3 (GPIO34 không có pull-up trong) |
| SEN0189 AO | 10k → GPIO35, 20k từ GPIO35 xuống GND. VCC 5V |
| JSN-SR04T | TRIG GPIO32, ECHO GPIO33 (qua phân áp 1k/2k nếu module chạy 5V). VCC 5V |
| Servo MG996R | tín hiệu GPIO13, nguồn **5V riêng 2A**, GND chung |
| Relay bơm | IN GPIO12, VCC 5V |
| LoRa SX1276 | NSS 5, RST 14, DIO0 26, SCK 18, MISO 19, MOSI 23, 3V3 |

Code: [first_flush.ino](first_flush.ino). Gói gửi về server: `F,CX01,HOLD,2.4,1830,85` (mã cửa xả, chế độ, mưa mm/10 phút, độ đục ADC, mực nước cm).

> Ngưỡng là số ước lượng, phải đo lại tại chỗ. Code chưa nạp thử trên board thật.
