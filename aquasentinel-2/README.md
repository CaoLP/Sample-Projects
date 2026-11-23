# AquaSentinel AI 2.0 — Đề xuất nâng cấp

**Từ "phát hiện xả thải lén" sang "chống ngập + chống ô nhiễm nước", và từ "cảnh báo" sang "hành động".**

![Kiến trúc 2.0](diagram.png)

## 1. Nhận xét bản hiện tại

**Điểm mạnh nên giữ:** trạm đo 5 thông số qua LoRa, bơm lấy mẫu làm bằng chứng (điểm khác biệt tốt), app Flutter có bản đồ + phản ánh hiện trường, web quản lý FastAPI, buồng đo inox + tấm đồng chống bám bẩn (sáng tạo, rẻ).

**Điểm yếu giám khảo dễ hỏi:**
1. Chỉ dừng ở *cảnh báo* và *lấy mẫu*. Chưa có gì tác động trực tiếp lên môi trường.
2. Mùa mưa nước đục và dâng do mưa sẽ kích hoạt báo động giả "xả thải" liên tục.
3. Cảnh báo chỉ đến người có smartphone/app. Người già, trẻ em, người đi đường không nhận được.
4. Cảm biến mực nước đã có (JSN-SR04T) nhưng chưa khai thác cho bài toán ngập.
5. Thiếu pH và lượng mưa. YF-S201 dễ tắc rác khi đặt ngoài kênh.

## 2. Ba lớp nâng cấp

### ① Biết trước
- **Hộp "Cột Báo Ngập"** gắn cột điện/cây gần khu dân cư, chợ, trường, hẻm hay ngập. Siêu âm chĩa xuống mặt đường nên mỗi hộp là **một điểm đo ngập**. Chạy pin mặt trời + LoRa, vẫn hoạt động khi bão làm mất điện và mất sóng 4G.
- **Bẫy rác thông minh** ở miệng cống/cửa xả: đo mức đầy lưới chắn rác.
- **Dữ liệu ngoài:** dự báo mưa (API thời tiết), lịch triều cường Đà Nẵng, ảnh người dân gửi.

### ② Xử lý bằng AI (server)
- **AI 1 – Phân biệt nguồn gây đục** ([classify.py](classify.py)). Mưa + nước dâng + đục tăng mà TDS loãng ra là nước chảy tràn. Không mưa + TDS tăng vọt ban đêm là nghi xả thải. Nhờ đó **một hệ thống dùng được cả 2 mùa** mà không báo động giả.
- **AI 2 – Dự báo ngập 1–3 giờ tới:** dựa trên mưa sắp tới, triều, độ sâu hiện tại, tốc độ dâng và độ đầy bẫy rác.
- **Bản đồ ngập thời gian thực:** nội suy độ sâu giữa các hộp, kết hợp ảnh người dân (AI ước lượng độ sâu từ bánh xe, bậc thềm). Tô màu tuyến đường và gợi ý đường tránh.

### ③ Hành động trực tiếp (phần "đột phá")
| Tác động | Cách làm | Đo hiệu quả bằng |
|---|---|---|
| Cảnh báo tại chỗ, không cần điện thoại | Hộp cột: đèn xanh/vàng/đỏ, loa giọng nói, bảng LED độ sâu ([flood_beacon.ino](flood_beacon.ino)) | Số phút cảnh báo sớm trước khi ngập |
| **Dọn cống TRƯỚC mưa** | Sắp mưa lớn trong 24h và bẫy rác > 60% thì tự tạo lệnh dọn cho tổ dân phố/tình nguyện viên. App tính điểm "Chiến binh xanh" | kg rác chặn được, số lần cống không tắc |
| **Tách first-flush** | 15–20 phút đầu cơn mưa đầu mùa (bẩn nhất): servo mở van dẫn nước qua bể lắng-lọc (cát, sỏi, than hoạt tính, cây thủy sinh) rồi mới ra kênh | TDS/độ đục trước và sau bể lọc |
| Cứu trợ chính xác | Nút SOS trên hộp cột gửi vị trí + độ sâu nước thật | Thời gian phản hồi yêu cầu |
| Giữ chức năng cũ | Lấy mẫu bằng chứng xả thải, và lấy thêm mẫu first-flush để so sánh | — |

## 3. Câu chuyện khi thuyết trình
> "Bản 1.0 giúp *phát hiện* ô nhiễm. Bản 2.0 giúp *ngăn* ô nhiễm và ngập: biết trước khi mưa, báo cho cả người không có điện thoại, và tự hành động dọn rác, lọc nước bẩn đầu mùa trước khi nó ra sông."

## 4. Mô hình demo trước giám khảo
- 1 trạm quan trắc (cũ) + 2 hộp cột (1 ở hẻm hay ngập, 1 ở chợ) + 1 bẫy rác + bể first-flush mô hình bằng hộp nhựa trong.
- Mô phỏng mưa bằng bình tưới. Đổ lá cây/rác vào lưới để kích hoạt lệnh dọn. Dâng nước trong khay để hộp cột chuyển vàng rồi đỏ và phát loa.

## 5. Linh kiện thêm (ước tính)
| Hạng mục | Linh kiện | Giá tham khảo |
|---|---|---|
| Hộp cột (mỗi hộp) | ESP32, LoRa SX1276 923MHz, JSN-SR04T, LED WS2812 12 bóng, DFPlayer Mini + loa 3W, nút nhấn chống nước, pin 18650 x2 + tấm pin mặt trời 6V, hộp IP65 | ~600–800k |
| Bẫy rác | Lưới inox, siêu âm hoặc loadcell 20kg + HX711 | ~200k |
| First-flush | Servo MG996R + van bi nhựa, cảm biến mưa, bể lọc tự chế | ~250k |
| Trạm cũ bổ sung | Cảm biến pH analog, cảm biến mưa tipping bucket | ~400k |

## 6. Lưu ý kỹ thuật
- **Tần số LoRa:** Việt Nam dùng băng 920–923 MHz (AS923) cho LoRa. Nên đổi RA-02 433 MHz sang module 915/923 MHz.
- **Đo lưu lượng:** YF-S201 dễ tắc rác ngoài kênh. Có thể ước lượng lưu lượng từ mực nước + tiết diện kênh, hoặc dùng phao đo vận tốc.
- **Bảo mật tài liệu:** bản PDF hiện có ghi tên và mật khẩu Wi-Fi thật. Nên xóa trước khi nộp hoặc chia sẻ công khai.

## Files
- `flood_beacon.ino`: firmware hộp Cột Báo Ngập (ESP32 + LoRa + siêu âm + LED + loa + SOS)
- `classify.py`: luật AI phân biệt chảy tràn / xả thải và điểm nguy cơ ngập (có self-test: `python3 classify.py`)

> Code mẫu để nhóm phát triển tiếp, chưa test trên phần cứng thật.
