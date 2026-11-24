// "Cột Báo Ngập" — hộp cảnh báo gắn cột điện/cây (AquaSentinel AI 2.0)
// ESP32 + LoRa SX1276 + JSN-SR04T (đo độ sâu nước mặt đường) + đèn tháp LED 3 màu có còi 12V + nút SOS
// Đèn tháp thay tấm LED chạy chữ: bền ngoài trời hơn, nhìn thấy từ xa, tốn điện ít hơn ~10 lần (đèn nháy, không sáng liên tục).
// Đèn loại CHUNG DƯƠNG: dây chung nối +12V, ESP32 kéo từng màu xuống GND qua ULN2003.
// Thư viện: LoRa (Sandeep Mistry)
#include <SPI.h>
#include <LoRa.h>

#define BEACON_ID  "B01"          // mỗi hộp một mã, server biết toạ độ theo mã
#define LORA_FREQ  923E6          // băng AS923 dùng ở VN
#define LORA_SS 5
#define LORA_RST 14
#define LORA_DIO0 26
#define TRIG 32
#define ECHO 33                   // qua cầu chia 1k/2k: ECHO của JSN-SR04T ra 5V
#define SOS_PIN 25
#define P_RED 27                  // -> ULN2003 IN1 -> OUT1 -> dây đỏ
#define P_YEL 4                   // -> IN2 -> OUT2 -> dây vàng
#define P_GRN 13                  // -> IN3 -> OUT3 -> dây xanh
#define P_BUZ 16                  // -> IN4 -> OUT4 -> dây còi

const float MOUNT_CM   = 250;     // khoảng cách cảm biến tới mặt đường khi khô (đo lúc lắp)
const float WARN_CM    = 10;      // nước sâu >= 10cm: vàng
const float DANGER_CM  = 30;      // >= 30cm: đỏ (xe máy dễ chết máy)

int level = 0;                    // 0 an toàn, 1 cảnh báo, 2 nguy hiểm
int serverLevel = 0;              // mức do trung tâm gửi xuống (dự báo), có thể cao hơn mức đo tại chỗ
float depth = 0;
unsigned long lastSend = 0, lastMeasure = 0, sosUntil = 0, levelSince = 0;

float readDepthCm() {             // trung vị 5 lần đo để lọc nhiễu sóng/mưa
  float v[5];
  for (int i = 0; i < 5; i++) {
    digitalWrite(TRIG, LOW); delayMicroseconds(2);
    digitalWrite(TRIG, HIGH); delayMicroseconds(20);
    digitalWrite(TRIG, LOW);
    long us = pulseIn(ECHO, HIGH, 30000);
    v[i] = us ? us * 0.0343 / 2 : MOUNT_CM;   // không có tiếng vọng: coi như khô
    delay(60);
  }
  for (int i = 0; i < 5; i++) for (int j = i + 1; j < 5; j++) if (v[j] < v[i]) { float t = v[i]; v[i] = v[j]; v[j] = t; }
  return max(0.0f, MOUNT_CM - v[2]);
}

// Bật trong khoảng [0, onMs) của mỗi chu kỳ periodMs
bool phase(unsigned long periodMs, unsigned long onMs) { return millis() % periodMs < onMs; }

// Kiểu nháy/còi theo mức. Còi kêu dồn 10s đầu khi lên mức, sau đó thưa lại để không làm phiền dân.
void updateLamp() {
  unsigned long t = millis() - levelSince;
  bool r = 0, y = 0, g = 0, b = 0;
  if (millis() < sosUntil) {                       // SOS: 3 màu chạy vòng + bíp ngắn mỗi 2s
    int k = (millis() / 300) % 3;
    r = k == 0; y = k == 1; g = k == 2;
    b = phase(2000, 150);
  } else if (level == 2) {                         // ĐỎ: nháy 2Hz, còi 3 bíp mỗi 30s
    r = phase(500, 250);
    b = t < 10000 ? phase(1000, 500) : (millis() % 30000 < 1500 && phase(500, 250));
  } else if (level == 1) {                         // VÀNG: nháy 1Hz, còi 1 bíp mỗi 120s
    y = phase(1000, 300);
    b = t < 10000 ? phase(2000, 300) : millis() % 120000 < 300;
  } else {                                         // XANH: chớp 0,1s mỗi 5s = "hộp đang sống", gần như không tốn điện
    g = phase(5000, 100);
  }
  digitalWrite(P_RED, r); digitalWrite(P_YEL, y); digitalWrite(P_GRN, g); digitalWrite(P_BUZ, b);
}

void sendLoRa(const String& msg) {
  LoRa.beginPacket(); LoRa.print(msg); LoRa.endPacket();
  LoRa.receive();
}

void setup() {
  Serial.begin(115200);
  pinMode(TRIG, OUTPUT); pinMode(ECHO, INPUT); pinMode(SOS_PIN, INPUT_PULLUP);
  for (int p : {P_RED, P_YEL, P_GRN, P_BUZ}) { pinMode(p, OUTPUT); digitalWrite(p, LOW); }
  // Tự kiểm khi bật nguồn: đỏ-vàng-xanh mỗi màu 0,5s + bíp ngắn -> người lắp biết đèn/còi còn tốt
  for (int p : {P_RED, P_YEL, P_GRN}) { digitalWrite(p, HIGH); delay(500); digitalWrite(p, LOW); }
  digitalWrite(P_BUZ, HIGH); delay(150); digitalWrite(P_BUZ, LOW);
  LoRa.setPins(LORA_SS, LORA_RST, LORA_DIO0);
  if (!LoRa.begin(LORA_FREQ)) Serial.println("LoRa FAIL");
  LoRa.setSpreadingFactor(10);    // tầm xa hơn, đủ cho gói nhỏ
  LoRa.receive();
}

void loop() {
  // 1) Nhận lệnh từ trung tâm: "ALL,2" hoặc "B01,1" (dự báo ngập / cảnh báo khẩn)
  if (LoRa.parsePacket()) {
    String p = LoRa.readString();
    int comma = p.indexOf(',');
    String to = p.substring(0, comma);
    if (comma > 0 && (to == "ALL" || to == BEACON_ID)) serverLevel = constrain(p.substring(comma + 1).toInt(), 0, 2);
  }

  // 2) Đo tại chỗ mỗi 2s, lấy mức cao hơn giữa đo và dự báo
  if (millis() - lastMeasure > 2000) {
    depth = readDepthCm();
    lastMeasure = millis();
  }
  int local = depth >= DANGER_CM ? 2 : depth >= WARN_CM ? 1 : 0;
  int lv = max(local, serverLevel);
  if (lv != level) levelSince = millis();          // đổi mức: còi kêu dồn lại 10s
  level = lv;

  // 3) Đèn + còi
  updateLamp();

  // 4) Nút SOS: gửi yêu cầu hỗ trợ kèm độ sâu, đèn chạy vòng 30s báo "đã gửi"
  if (digitalRead(SOS_PIN) == LOW && millis() > sosUntil) {
    sendLoRa(String("SOS,") + BEACON_ID + "," + String(depth, 0));
    sosUntil = millis() + 30000;
  }

  // 5) Báo độ sâu về trung tâm: 60s khi khô, 10s khi có nước (tiết kiệm pin)
  if (millis() - lastSend > (local ? 10000UL : 60000UL)) {
    sendLoRa(String("D,") + BEACON_ID + "," + String(depth, 0));
    lastSend = millis();
  }
  delay(20);
}
