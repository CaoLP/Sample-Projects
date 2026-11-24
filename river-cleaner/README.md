# Thuyền vớt rác IoT – động cơ, L298N, mạch công suất

## 1. Chọn động cơ (để dùng được L298N)

L298N chỉ chịu **2 A liên tục / kênh** (đỉnh ~3 A) và sụt **~2 V** (12 V vào → motor nhận ~10 V).
→ Chọn motor giảm tốc 12 V có **dòng chạy < 1 A, dòng kẹt < 3 A**.

| Bộ phận | Động cơ đề xuất | Lý do |
|---|---|---|
| 2 bánh guồng | **JGB37-520 12 V, 60–100 rpm** ×2 | Guồng Ø20 cm ở 60 rpm → mép guồng ~0,6 m/s, đủ cho thuyền ~25 kg chạy chậm vớt rác. Mô-men định mức ~4–6 kg·cm |
| Băng tải | **JGB37-520 12 V, 30 rpm** ×1 | Tốc độ chậm, mô-men cao (~8–10 kg·cm) để kéo rác ướt 1–2 kg |

Không dùng motor gạt nước ô tô với L298N (chạy 3–5 A, kẹt 15–20 A → cháy L298N). Nếu muốn motor gạt nước thì thay L298N bằng **BTS7960 43 A**, code gần như giữ nguyên (RPWM/LPWM thay IN1/IN2).

Motor JGB37 **không chống nước**: đặt trên mặt nước, trục ra guồng qua bạc đạn + mỡ bò, phủ chụp nhựa.

## 2. Nối ESP32 ↔ L298N (chế độ 2 chân, giữ jumper ENA/ENB)

| ESP32 DevKit V1 | L298N #1 (guồng) | | ESP32 | L298N #2 (băng tải) |
|---|---|---|---|---|
| GPIO25 | IN1 (trái) | | GPIO4 | IN1 |
| GPIO27 | IN2 (trái) | | GPIO13 | IN2 |
| GPIO32 | IN3 (phải) | | | |
| GPIO33 | IN4 (phải) | | | |
| GND | GND | | GND | GND |

- Motor trái → OUT1/OUT2, phải → OUT3/OUT4, băng tải → OUT1/OUT2 của #2.
- ESP32 xuất 3,3 V vẫn kích được L298N (ngưỡng ~2,3 V).
- **GND phải nối chung** giữa pin, L298N và ESP32.
- Jumper 5 V trên L298N: giữ được khi nguồn vào ≤ 12 V, nhưng **không lấy 5 V này nuôi ESP32** (nhiễu motor) – dùng buck riêng.

## 3. Mạch công suất

```
Pin LiFePO4 12,8 V 20 Ah
   │
 [Cầu chì 10 A] ── [Công tắc ngắt khẩn cấp (nút đỏ)]
   │
   ├── INA219 (đo V, A) ── BUS 12 V
   │                         ├─[cầu chì 5 A]─ L298N #1 (+12V)  ← tụ 1000 µF 25 V sát cọc
   │                         ├─[cầu chì 3 A]─ L298N #2 (+12V)  ← tụ 470 µF 25 V
   │                         └─[cầu chì 2 A]─ Buck LM2596/XL4015 → 5 V 3 A
   │                                              ├─ ESP32 (chân 5V/VIN)  ← tụ 470 µF
   │                                              └─ cảm biến, LoRa (3,3 V từ ESP32)
   │
 Pin mặt trời 50 W ── Sạc MPPT (chế độ LiFePO4) ── vào pin
```

- Mỗi motor hàn **3 tụ gốm 100 nF** (1 giữa 2 cực, 2 từ mỗi cực ra vỏ) để giảm nhiễu reset ESP32.
- Module L298N đã có 8 diode xả, không cần thêm.
- L298N tỏa nhiệt ~2 W/kênh → giữ tản nhiệt, để hộp có khe thoáng phía dưới / quạt nhỏ.
- Dây: nhánh motor ≥ 0,75 mm², nhánh pin chính ≥ 1,5 mm². Đầu cos + co nhiệt, hộp IP67 + ốc siết cáp.

## 4. Thử

1. Chưa lắp guồng: nạp `motor_test.ino`, mở Serial 115200, gõ `w s a d x b 1..9`.
2. Đo dòng mỗi motor bằng INA219/đồng hồ: nếu **> 1,5 A khi chạy** → chuyển sang BTS7960.
3. Không gửi lệnh 1,5 s → guồng tự dừng (failsafe). Giai đoạn sau thay Serial bằng tay RC FS-i6.

Chưa thử trên phần cứng; số mô-men/tốc độ là ước tính theo datasheet motor phổ biến.
