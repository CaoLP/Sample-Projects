// "Cột Báo Ngập" — hộp cảnh báo gắn cột điện/cây (AquaSentinel AI 2.0)
// ESP32 + LoRa SX1276 + JSN-SR04T (đo độ sâu nước mặt đường) + LED WS2812 + DFPlayer Mini + loa + nút SOS
// Thư viện: LoRa (Sandeep Mistry), Adafruit NeoPixel, DFRobotDFPlayerMini
// Thẻ SD của DFPlayer: 0001.mp3 "Khu vực an toàn", 0002.mp3 "Nước đang dâng, chú ý",
//                      0003.mp3 "Ngập sâu, không đi qua, di chuyển lên chỗ cao", 0004.mp3 "Đã gửi yêu cầu hỗ trợ"
#include <SPI.h>
#include <LoRa.h>
#include <Adafruit_NeoPixel.h>
#include <DFRobotDFPlayerMini.h>

#define BEACON_ID  "B01"          // mỗi hộp một mã, server biết toạ độ theo mã
#define LORA_FREQ  923E6          // băng AS923 dùng ở VN
#define LORA_SS 5
#define LORA_RST 14
#define LORA_DIO0 26
#define TRIG 32
#define ECHO 33
#define LED_PIN 27
#define LED_N 12
#define SOS_PIN 25

const float MOUNT_CM   = 250;     // khoảng cách cảm biến tới mặt đường khi khô (đo lúc lắp)
const float WARN_CM    = 10;      // nước sâu >= 10cm: vàng
const float DANGER_CM  = 30;      // >= 30cm: đỏ (xe máy dễ chết máy)

Adafruit_NeoPixel led(LED_N, LED_PIN, NEO_GRB + NEO_KHZ800);
HardwareSerial dfSerial(2);       // RX2=16, TX2=17 -> DFPlayer
DFRobotDFPlayerMini player;

int level = -1;                   // 0 an toàn, 1 cảnh báo, 2 nguy hiểm (mức đang phát)
int serverLevel = 0;              // mức do trung tâm gửi xuống (dự báo), có thể cao hơn mức đo tại chỗ
unsigned long lastSend = 0, lastVoice = 0;

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

void showLevel(int lv) {
  uint32_t c = lv == 2 ? led.Color(255, 0, 0) : lv == 1 ? led.Color(255, 160, 0) : led.Color(0, 180, 0);
  led.fill(c); led.show();
}

void sendLoRa(const String& msg) {
  LoRa.beginPacket(); LoRa.print(msg); LoRa.endPacket();
  LoRa.receive();
}

void setup() {
  Serial.begin(115200);
  pinMode(TRIG, OUTPUT); pinMode(ECHO, INPUT); pinMode(SOS_PIN, INPUT_PULLUP);
  led.begin(); led.setBrightness(120);
  dfSerial.begin(9600, SERIAL_8N1, 16, 17);
  if (player.begin(dfSerial)) player.volume(28);
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

  // 2) Đo tại chỗ, lấy mức cao hơn giữa đo thực tế và dự báo
  float depth = readDepthCm();
  int local = depth >= DANGER_CM ? 2 : depth >= WARN_CM ? 1 : 0;
  int lv = max(local, serverLevel);

  // 3) Đổi đèn + phát loa khi mức thay đổi; nhắc lại mỗi 5 phút khi còn nguy hiểm
  if (lv != level || (lv == 2 && millis() - lastVoice > 300000)) {
    showLevel(lv);
    player.play(lv + 1);
    lastVoice = millis();
    level = lv;
  }

  // 4) Nút SOS: gửi yêu cầu hỗ trợ kèm độ sâu
  if (digitalRead(SOS_PIN) == LOW) {
    sendLoRa(String("SOS,") + BEACON_ID + "," + String(depth, 0));
    player.play(4);
    delay(1000);
  }

  // 5) Báo độ sâu về trung tâm: 60s khi khô, 10s khi có nước (tiết kiệm pin)
  if (millis() - lastSend > (local ? 10000UL : 60000UL)) {
    sendLoRa(String("D,") + BEACON_ID + "," + String(depth, 0));
    lastSend = millis();
  }
}
