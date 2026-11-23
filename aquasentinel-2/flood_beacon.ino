// "Cột Báo Ngập" — hộp cảnh báo gắn cột điện/cây (AquaSentinel AI 2.0)
// ESP32 + LoRa SX1276 + JSN-SR04T (đo độ sâu nước mặt đường) + tấm LED WS2812B 8x32 chạy chữ + nút SOS
// Tấm LED thay cho loa + dải LED cũ: 1 dây tín hiệu, chữ chạy đổi màu xanh/vàng/đỏ theo mức ngập.
// Thư viện: LoRa (Sandeep Mistry), Adafruit NeoMatrix (kéo theo Adafruit GFX + NeoPixel)
#include <SPI.h>
#include <LoRa.h>
#include <Adafruit_NeoMatrix.h>

#define BEACON_ID  "B01"          // mỗi hộp một mã, server biết toạ độ theo mã
#define LORA_FREQ  923E6          // băng AS923 dùng ở VN
#define LORA_SS 5
#define LORA_RST 14
#define LORA_DIO0 26
#define TRIG 32
#define ECHO 33
#define LED_PIN 27                // DIN tấm LED (qua điện trở 330Ω)
#define SOS_PIN 25

const float MOUNT_CM   = 250;     // khoảng cách cảm biến tới mặt đường khi khô (đo lúc lắp)
const float WARN_CM    = 10;      // nước sâu >= 10cm: vàng
const float DANGER_CM  = 30;      // >= 30cm: đỏ (xe máy dễ chết máy)

// Tấm 8x32 dẻo phổ biến: đi dây theo cột, zigzag. Nếu chữ bị ngược/lộn: đổi TOP->BOTTOM hoặc LEFT->RIGHT.
Adafruit_NeoMatrix mx(32, 8, LED_PIN, NEO_MATRIX_TOP + NEO_MATRIX_LEFT + NEO_MATRIX_COLUMNS + NEO_MATRIX_ZIGZAG, NEO_GRB + NEO_KHZ800);

int level = 0;                    // 0 an toàn, 1 cảnh báo, 2 nguy hiểm
int serverLevel = 0;              // mức do trung tâm gửi xuống (dự báo), có thể cao hơn mức đo tại chỗ
float depth = 0;
unsigned long lastSend = 0, lastMeasure = 0, lastFrame = 0, sosUntil = 0;
int scrollX = 32;
String text = "AN TOAN";

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

// Font mặc định không có dấu tiếng Việt nên viết không dấu.
String message(int lv) {
  String d = String(depth, 0) + "cm";
  if (millis() < sosUntil) return "DA GUI SOS - CUU HO DANG DEN";
  if (lv == 2) return "NGAP " + d + " - KHONG DI QUA - LEN CHO CAO";
  if (lv == 1) return "CHU Y: NUOC DANG " + d;
  return "AN TOAN " + d;
}

void drawFrame() {                // gọi mỗi 40ms: chữ chạy từ phải sang trái
  uint16_t c = millis() < sosUntil ? mx.Color(0, 120, 255) : level == 2 ? mx.Color(255, 0, 0) : level == 1 ? mx.Color(255, 150, 0) : mx.Color(0, 200, 0);
  mx.fillScreen(0);
  mx.setTextColor(c);
  mx.setCursor(scrollX, 0);
  mx.print(text);
  mx.show();
  if (--scrollX < -(int)text.length() * 6) { scrollX = mx.width(); text = message(level); }  // hết 1 lượt mới đổi chữ, không bị giật
}

void sendLoRa(const String& msg) {
  LoRa.beginPacket(); LoRa.print(msg); LoRa.endPacket();
  LoRa.receive();
}

void setup() {
  Serial.begin(115200);
  pinMode(TRIG, OUTPUT); pinMode(ECHO, INPUT); pinMode(SOS_PIN, INPUT_PULLUP);
  mx.begin(); mx.setTextWrap(false);
  mx.setBrightness(60);           // 60/255 đủ đọc ban đêm; ban ngày nắng tăng lên 120 (tốn pin hơn)
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

  // 2) Đo tại chỗ mỗi 2s (đo mất ~0.3s, đo liên tục sẽ làm chữ chạy giật), lấy mức cao hơn giữa đo và dự báo
  if (millis() - lastMeasure > 2000) {
    depth = readDepthCm();
    lastMeasure = millis();
  }
  int local = depth >= DANGER_CM ? 2 : depth >= WARN_CM ? 1 : 0;
  int lv = max(local, serverLevel);
  if (lv > level) { scrollX = mx.width(); text = message(lv); }  // mức tăng: đổi chữ ngay, không chờ hết lượt
  level = lv;

  // 3) Chữ chạy
  if (millis() - lastFrame > 40) { drawFrame(); lastFrame = millis(); }

  // 4) Nút SOS: gửi yêu cầu hỗ trợ kèm độ sâu, tấm LED hiện "DA GUI SOS" 30s
  if (digitalRead(SOS_PIN) == LOW && millis() > sosUntil) {
    sendLoRa(String("SOS,") + BEACON_ID + "," + String(depth, 0));
    sosUntil = millis() + 30000;
    scrollX = mx.width(); text = message(level);
  }

  // 5) Báo độ sâu về trung tâm: 60s khi khô, 10s khi có nước (tiết kiệm pin)
  if (millis() - lastSend > (local ? 10000UL : 60000UL)) {
    sendLoRa(String("D,") + BEACON_ID + "," + String(depth, 0));
    lastSend = millis();
  }
}
