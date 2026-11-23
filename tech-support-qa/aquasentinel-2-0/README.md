# AquaSentinel 2.0 – từ "cảnh báo" sang "can thiệp trực tiếp"

Đề xuất nâng cấp đề tài AquaSentinel AI (quan trắc nước + cảnh báo xả thải + tự lấy mẫu bằng LoRa) theo yêu cầu của bạn Tuệ:
mở rộng sang **ngập lụt + ô nhiễm nước đô thị**, giữ nguyên chức năng cũ, thêm **hộp cảnh báo gắn tại cột/cây khu dân cư và chợ**, **bản đồ ngập**, xử lý **rác và first flush đầu mùa mưa**, và quan trọng nhất: **tác động trực tiếp**, không chỉ báo rồi gọi cứu trợ.

> Căn cứ: đã đọc báo cáo 37 trang (phần giải pháp, phần cứng, app/web). Đây là đề xuất thiết kế và kế hoạch thí nghiệm, **chưa có số liệu đo thật**. Các con số kỹ thuật cần được đo lại trên mô hình trước khi đưa vào báo cáo.

---

## 1. Vấn đề của bản hiện tại

| Hạn chế | Hệ quả khi bảo vệ trước hội đồng |
|---|---|
| Chỉ *phát hiện* xả thải rồi báo | "Nhiều đề tài IoT cũng đo TDS, độ đục rồi gửi app" – khó thấy khác biệt |
| Chỉ cảnh báo, gọi cứu trợ | Hậu quả vẫn xảy ra, giá trị nằm ở thông tin chứ không ở kết quả |
| Một điểm đo ở nguồn xả | Không nhìn được bức tranh cả khu vực, không dự báo được diễn biến |

**Hướng giải quyết:** đưa hệ thống đi qua 3 cấp: *Thấy → Dự báo → Làm gì đó ngay*. Điểm sáng tạo nằm ở cấp thứ ba.

---

## 2. Ý tưởng cốt lõi: vòng điều khiển kín tại chỗ

Ý tưởng chủ đạo (đặt tên gợi ý): **"Mưa đến – Cống tự lo"**. Mỗi vòng dưới đây tự chạy bằng ESP32 tại chỗ, **không cần internet** (LoRa + logic cục bộ), app chỉ để giám sát.

### Vòng 1 – Cống tự báo tắc để dọn *trước* khi ngập (ngăn chặn nguyên nhân)
- Đặt siêu âm đo mực nước **thượng lưu và hạ lưu** của song chắn rác/miệng cống.
- Chênh mực nước giữa hai phía tăng mà mưa không tăng ⇒ **cống đang tắc**.
- Hệ thống tính **chỉ số tắc nghẽn** cho từng cống, xếp hạng và **giao việc cho tổ dọn vệ sinh** (tổ dân phố, đoàn viên) trên app, kèm ảnh xác nhận trước/sau.
- Cuối mùa khô, chạy **chiến dịch "Dọn trước mưa"**: ưu tiên cống có chỉ số cao nhất ở khu chợ, khu dân cư thấp trũng.
- Tác động trực tiếp: giảm rác trôi ra kênh/sông và giảm điểm ngập do tắc cống. Đo được bằng kg rác thu gom, số cống được dọn.

### Vòng 2 – Bộ tách dòng đầu mùa mưa (first flush)
- Nước mưa đầu mùa cuốn rác, dầu mỡ, bụi, chất hữu cơ tích tụ suốt mùa khô: đây là đợt ô nhiễm nặng nhất.
- Bộ điều khiển dùng **cảm biến mưa + độ đục/TDS** (đã có sẵn trong đề tài) để quyết định: khi mưa bắt đầu, **van điện từ chuyển dòng đầu vào bể lắng/lọc nhỏ** thay vì cho chảy thẳng ra kênh; khi nước đã "sạch" tương đối (độ đục xuống dưới ngưỡng, hoặc đủ lượng mưa đặt trước) thì **đóng nhánh bể, mở dòng chính**.
- Nước sau lắng/lọc (cát – sỏi – than sinh học làm từ cành cây rụng) dùng **tưới cây, rửa đường chợ**, góp phần giảm nóng đô thị.
- Thông số "bao nhiêu mm mưa đầu" hay "bao nhiêu phút" **không cố định**: tài liệu quốc tế thường dùng khoảng vài mm mưa đầu hoặc vài chục phút đầu, nhưng phải **đo thực tế** để chọn (đây chính là một thí nghiệm của đề tài).

Logic gợi ý (chạy trên ESP32):
```
nếu đang KHÔNG mưa:                      van_bể = ĐÓNG, van_chính = MỞ
nếu bắt đầu mưa và bể chưa đầy:          van_bể = MỞ, van_chính = ĐÓNG   (thu dòng đầu)
nếu độ_đục < ngưỡng_sạch trong 3 phút
   hoặc lượng_mưa_tích_lũy > mm_đặt
   hoặc bể đầy:                          van_bể = ĐÓNG, van_chính = MỞ   (qua first flush)
luôn luôn: nếu mực nước thượng lưu > mức_nguy_hiểm → MỞ van_chính ngay (ưu tiên thoát lũ)
```
Dòng cuối là **ràng buộc an toàn**: tách first flush không bao giờ được làm kẹt thoát nước khi mưa lớn.

### Vòng 3 – Xả trước bể chứa để "nhường chỗ" cho lũ (giảm đỉnh lũ cục bộ)
- Chợ, trường học, nhà văn hóa có thể có **bể/thùng trữ nước mưa** nhỏ. Hầu hết luôn đầy nên vô dụng khi lũ đến.
- Khi hệ thống **dự báo mưa lớn** (tốc độ tăng của lượng mưa + dự báo thời tiết công khai), van tự **xả bớt bể trước 1–2 giờ**, tới mức an toàn đã đặt, rồi thu nước mưa vào lại.
- Tác động: giảm lượng nước đổ ra đường trong đỉnh mưa tại điểm đó. Mỗi điểm nhỏ, nhưng nhiều điểm cộng lại. **Cần mô hình hóa để chứng minh hiệu quả, không tuyên bố tuyệt đối.**

---

## 3. Mạng "Cột Canh" – hộp cảnh báo ở cột điện, cây xanh

Mỗi nút gồm: ESP32 + LoRa (sẵn có), siêu âm JSN-SR04T đo mực nước, cảm biến mưa (gầu lật), pin + năng lượng mặt trời, còi và đèn LED nhiều màu (xanh/vàng/cam/đỏ), tùy chọn loa phát giọng nói.

| Mức | Điều kiện (ví dụ, phải hiệu chỉnh) | Hành động tại chỗ |
|---|---|---|
| Xanh | Mực nước bình thường | Đèn xanh |
| Vàng | Mực nước tăng nhanh hơn ngưỡng | Đèn vàng nhấp nháy, gửi tin lên app |
| Cam | Dự báo chạm ngưỡng ngập trong X phút | Đèn cam + còi ngắt quãng, phát hướng dẫn |
| Đỏ | Vượt ngưỡng nguy hiểm | Đèn đỏ + còi liên tục, báo tổ dân phố, kích hoạt vòng 3 |

- **Chạy khi mất internet và mất điện lưới**: nút trao đổi qua LoRa, nút cảnh báo cục bộ không phụ thuộc server. Đây là lợi thế thật so với app thuần mạng.
- **Cảnh báo "thời gian còn lại"** thay vì chỉ "đang ngập": tính tốc độ dâng mực nước, ngoại suy tuyến tính ra thời điểm chạm ngưỡng. Bắt đầu bằng ngoại suy đơn giản, mô hình AI nhẹ (hồi quy) là phần nâng cấp, huấn luyện bằng dữ liệu đo được.
- **Lưu ý thực tế khi gắn ở cột điện:** không tự ý gắn lên cột của điện lực; cần xin phép đơn vị quản lý. Dùng nguồn 12 V/pin mặt trời riêng, vỏ chống nước tối thiểu IP65, chống sét lan truyền, buộc đai không khoan vào cây. Với đề tài thi, có thể trình diễn trên cột mô hình.
- JSN-SR04T có **vùng mù khoảng 25 cm gần đầu dò**: lắp cao hơn mực nước tối đa ít nhất bằng khoảng này.

---

## 4. Bản đồ ngập

Nguồn dữ liệu: (1) các nút Cột Canh, (2) người dân báo qua app (kèm ảnh, vị trí GPS, độ sâu ước lượng), (3) lượng mưa.
- Hiển thị các nút và báo cáo trên bản đồ (OpenStreetMap), tô màu theo mức.
- Giữa các nút dùng nội suy khoảng cách ngược (IDW) làm **bản đồ nguy cơ** gần đúng; *ghi rõ là nội suy*, không phải đo.
- Tuyến đường **nên tránh** và **điểm tập kết an toàn** hiển thị trong app; dữ liệu cao độ (DEM) mịn là phần mở rộng.
- Mỗi điểm ngập được lưu lịch sử ⇒ sau mùa mưa, **bản đồ điểm nóng ngập** giúp chính quyền ưu tiên nạo vét, cải tạo.

---

## 5. Giữ nguyên và tận dụng chức năng cũ

| Chức năng cũ | Vai trò trong bản 2.0 |
|---|---|
| Cảm biến TDS, độ đục, nhiệt độ, lưu lượng | Dùng để **ra quyết định first flush** và phát hiện xả thải lén |
| Siêu âm đo mực nước | Đo mực nước cho cảnh báo ngập và phát hiện tắc cống |
| Tự lấy mẫu nước khi vượt ngưỡng | Giữ nguyên: lấy mẫu làm **bằng chứng** khi xả thải, thêm **lấy mẫu dòng đầu mùa mưa** để đánh giá ô nhiễm |
| LoRa + MQTT + Flutter + cổng web | Hạ tầng truyền thông chung cho các nút mới |
| Hỏi đáp AI | Thêm kiến thức: cách ứng phó ngập, ai liên hệ khi tắc cống, hướng dẫn sơ tán |

---

## 6. Tác động đo được (bảng chỉ số cho báo cáo)

| Chỉ số | Cách đo |
|---|---|
| Hiệu quả tách first flush | Độ đục/TSS/TDS trước và sau bể lắng (% giảm) trên mô hình mưa nhân tạo |
| Lượng rác thu gom trước mùa mưa | kg rác theo cống, số cống dọn |
| Lượng nước giữ lại / tái sử dụng | m³ vào bể, m³ dùng tưới |
| Thời gian báo trước ngập | Phút từ lúc cảnh báo cam đến lúc mực nước chạm ngưỡng |
| Tỷ lệ báo động giả/bỏ sót | Trên các lần thử |
| Phát hiện cống tắc | Độ chính xác khi cố ý chặn cống mô hình |
| Phạm vi LoRa | Khoảng cách hoạt động thực tế trong khu đô thị |
| Giảm đỉnh dòng chảy (vòng 3) | So sánh lưu lượng đỉnh có/không xả trước trên mô hình |

---

## 7. Thí nghiệm gợi ý (làm được với mô hình thu nhỏ)

1. **Khay mưa nhân tạo:** máng nghiêng, bình tưới tạo mưa, rải đất/rác/dầu thử để mô phỏng "mùa khô tích bụi". Đo độ đục theo thời gian ⇒ tìm ngưỡng first flush.
2. **Tách dòng đầu:** so sánh nước ra có và không có bộ tách + bể lắng.
3. **Cống tắc:** chặn một phần mô hình bằng rác, kiểm tra chỉ số tắc nghẽn.
4. **Cảnh báo sớm:** nâng mực nước với các tốc độ khác nhau, đo thời gian báo trước và báo động giả.
5. **Vòng 3:** hai bể mô hình, một có xả trước, một không, so sánh đỉnh lưu lượng.

An toàn thí nghiệm: không dùng hóa chất độc, không thử trên nguồn nước thật khi chưa được phép; điện 12 V, tách nguồn khỏi nước.

---

## 8. Giới hạn cần nói thẳng với hội đồng

- Hệ thống **hỗ trợ**, **không thay thế** cảnh báo chính thức của cơ quan khí tượng/phòng chống thiên tai. Khi có lệnh chính thức, làm theo lệnh đó.
- Chất lượng nước đo bằng TDS và độ đục chỉ là **chỉ báo gián tiếp**, không kết luận chất độc cụ thể hay mức an toàn uống.
- Bản đồ giữa các nút là **nội suy**, có sai số lớn nơi ít nút.
- Vòng 3 có thể **không hiệu quả** nếu bể quá nhỏ so với diện tích lưu vực: cần tính toán và nói rõ phạm vi áp dụng (điểm chợ, trường học, không phải cứu cả thành phố).
- Van tự động là cơ cấu chấp hành: phải có **chế độ an toàn khi mất điện** (van thoát lũ mặc định mở), có cơ chế thủ công.
- Chưa có dữ liệu thực địa; mọi con số hiệu quả cần được đo.

---

## 9. Câu hỏi hội đồng có thể hỏi

1. *Khác gì các đề tài IoT đo nước khác?* ⇒ Đóng vòng điều khiển: tách first flush, báo cống tắc để dọn trước, xả trước bể; hoạt động khi mất mạng.
2. *Lợi ích khí hậu ở đâu?* ⇒ Giảm rác/chất hữu cơ phân hủy trôi ra sông, giữ nước mưa tái sử dụng tưới cây giảm nóng, giảm đỉnh lũ cục bộ. Nói là **thích ứng và giảm thiểu cục bộ**, không tuyên bố giảm biến đổi khí hậu toàn cầu.
3. *Báo động giả thì sao?* ⇒ Có ngưỡng nhiều mức, lọc nhiễu, xác nhận từ người dân, thống kê tỷ lệ giả trong thí nghiệm.
4. *Chi phí / bảo trì?* ⇒ Linh kiện phổ thông, năng lượng mặt trời; bảo trì cảm biến (rêu, bùn, rác bám) cần có lịch; đã tính vào kế hoạch.
5. *Ai vận hành?* ⇒ Tổ dân phố/đoàn thanh niên nhận việc dọn trên app; cổng web cho cơ quan quản lý.

---

## 10. Lộ trình triển khai (gợi ý)

| Giai đoạn | Việc làm |
|---|---|
| 1 | Nút Cột Canh: mực nước + mưa + còi/đèn, truyền LoRa, hiển thị lên app hiện có |
| 2 | Bản đồ ngập + báo cáo từ người dân + nhật ký điểm ngập |
| 3 | Cảm biến cống tắc, giao việc dọn trên app |
| 4 | Bộ tách first flush (van, bể lắng) trên mô hình |
| 5 | Xả trước bể (vòng 3), mô hình AI dự báo thời gian ngập |

Nên chọn **vòng 2 (first flush) + mạng Cột Canh + cống tắc** làm điểm nhấn chính cho đề tài; vòng 3 trình bày như hướng phát triển nếu chưa kịp thí nghiệm.

---

## 11. Em có thể làm tiếp (khi bạn muốn)
- Firmware ESP32 cho nút Cột Canh và bộ điều khiển first flush (có sẵn logic ở mục 2).
- Thêm màn hình bản đồ ngập và giao việc dọn cống vào app Flutter.
- Viết lại phần Tóm tắt, Tính mới – sáng tạo của báo cáo theo hướng 2.0.
- Bộ mô phỏng nhỏ để thử logic first flush và cảnh báo thời gian ngập trước khi làm mạch.
