// "Cửa Xả Thông Minh" — giữ lại nước mưa đợt đầu (first-flush) tại giếng tách dòng của cửa xả ven biển (AquaSentinel AI 2.0)
// Thực tế Đà Nẵng: cống chung nước mưa + nước thải. Trời khô: đập tràn dẫn nước thải vào cống bao -> trạm bơm -> nhà máy XLNT.
// Mưa lớn: nước tràn đập ra biển, đợt đầu cuốn bùn thải đọng trong cống nên nước ra biển đen. Hộp này:
//   - Mưa bắt đầu: giữ cửa phai ra biển đóng, bật bơm đẩy nước đợt đầu vào cống bao/bể chứa.
//   - Đục giảm (nước đã sạch hơn) hoặc đã giữ đủ thời gian: mở cửa ra biển.
//   - Nước trong giếng lên cao (nguy cơ ngập phố): mở cửa ngay, chống ngập ưu tiên hơn chống ô nhiễm.
// Mô hình demo: servo MG996R kéo tấm cửa phai mica, bơm 12V mini qua relay. Ngoài thực tế: thay bằng điều khiển
// cửa phai điện và trạm bơm có sẵn của cửa xả (chỉ đưa tín hiệu cho đơn vị vận hành, không tự can thiệp).
// Thư viện: ESP32Servo, LoRa (Sandeep Mistry)
#include <SPI.h>
#include <LoRa.h>
#include <ESP32Servo.h>

#define OUTFALL_ID "CX01"
#define RAIN_PIN 34      // cảm biến mưa tipping bucket (công tắc lá), mỗi lần lật = 0.2mm
#define TURB_PIN 35      // cảm biến độ đục analog (SEN0189) qua phân áp 10k/20k (5V -> 3.3V)
#define TRIG 32          // JSN-SR04T đo mực nước trong giếng tách dòng
#define ECHO 33
#define SERVO_PIN 13     // cửa phai ra biển
#define PUMP_PIN 12      // relay bơm vào cống bao
#define LORA_SS 5
#define LORA_RST 14
#define LORA_DIO0 26

// Ngưỡng: đo tại chỗ lúc trời khô và trong 2-3 cơn mưa đầu rồi sửa lại.
const float RAIN_START_MM = 1.0;       // mưa >= 1mm trong 10 phút: bắt đầu giữ đợt đầu
const int   TURB_CLEAN    = 2500;      // ADC cao = trong (SEN0189 càng đục điện áp càng thấp)
const unsigned long HOLD_MIN_MS = 10UL * 60000, HOLD_MAX_MS = 30UL * 60000;
const float MOUNT_CM = 200;            // khoảng cách cảm biến tới đáy giếng
const float LEVEL_OPEN_CM = 120;       // nước trong giếng >= 120cm: mở cửa ngay chống ngập
const int GATE_CLOSED = 0, GATE_OPEN = 90;

enum Mode { DRY, HOLD, RELEASE, FLOOD };
const char* NAMES[] = {"DRY", "HOLD", "RELEASE", "FLOOD"};
Mode mode = DRY;
volatile int tips = 0;
int tipLog[10] = {0};                  // số lần lật mỗi phút, 10 phút gần nhất
unsigned long holdStart = 0, lastMin = 0, lastSend = 0, dryFor = 0;
Servo gate;

void IRAM_ATTR onTip() { static unsigned long t = 0; if (millis() - t > 200) { tips++; t = millis(); } }  // chống dội

float rain10mm() { int s = tips; for (int v : tipLog) s += v; return s * 0.2; }

float levelCm() {
  digitalWrite(TRIG, LOW); delayMicroseconds(2); digitalWrite(TRIG, HIGH); delayMicroseconds(20); digitalWrite(TRIG, LOW);
  long us = pulseIn(ECHO, HIGH, 30000);
  return us ? max(0.0f, MOUNT_CM - us * 0.0343f / 2) : 0;
}

int turbidity() { long s = 0; for (int i = 0; i < 10; i++) { s += analogRead(TURB_PIN); delay(5); } return s / 10; }

// Quyết định chế độ: tách riêng cho dễ đọc và dễ thử.
Mode decide(Mode m, float rain, int turb, float level, unsigned long held) {
  if (level >= LEVEL_OPEN_CM) return FLOOD;                       // an toàn chống ngập trước
  if (m == FLOOD) return level < LEVEL_OPEN_CM - 20 ? RELEASE : FLOOD;  // trễ 20cm cho khỏi đóng mở liên tục
  if (m == DRY) return rain >= RAIN_START_MM ? HOLD : DRY;
  if (m == HOLD) return (held >= HOLD_MIN_MS && turb >= TURB_CLEAN) || held >= HOLD_MAX_MS ? RELEASE : HOLD;
  return m;                                                       // RELEASE: về DRY khi tạnh 60 phút (xử lý ở loop)
}

void apply(Mode m) {
  gate.write(m == HOLD || m == DRY ? GATE_CLOSED : GATE_OPEN);
  digitalWrite(PUMP_PIN, m == HOLD ? HIGH : LOW);                 // DRY: nước thải tự chảy qua đập tràn, không cần bơm
}

void setup() {
  Serial.begin(115200);
  pinMode(RAIN_PIN, INPUT_PULLUP); attachInterrupt(RAIN_PIN, onTip, FALLING);
  pinMode(TRIG, OUTPUT); pinMode(ECHO, INPUT); pinMode(PUMP_PIN, OUTPUT);
  gate.attach(SERVO_PIN); apply(mode);
  LoRa.setPins(LORA_SS, LORA_RST, LORA_DIO0);
  if (!LoRa.begin(923E6)) Serial.println("LoRa FAIL");
  LoRa.setSpreadingFactor(10);
}

void loop() {
  if (millis() - lastMin >= 60000) {   // dồn số lần lật vào cửa sổ 10 phút
    for (int i = 9; i > 0; i--) tipLog[i] = tipLog[i - 1];
    tipLog[0] = tips; tips = 0; lastMin = millis();
    dryFor = rain10mm() == 0 ? dryFor + 1 : 0;
    if (mode == RELEASE && dryFor >= 60) mode = DRY;  // tạnh 60 phút: sẵn sàng cho cơn mưa sau
  }
  float rain = rain10mm(), level = levelCm();
  int turb = turbidity();
  Mode next = decide(mode, rain, turb, level, millis() - holdStart);
  if (next != mode) {
    if (next == HOLD) holdStart = millis();
    mode = next; apply(mode);
    Serial.printf("-> %s\n", NAMES[mode]);
  }
  if (millis() - lastSend > (mode == DRY ? 60000UL : 10000UL)) {  // "F,CX01,HOLD,2.4,1830,85"
    LoRa.beginPacket();
    LoRa.printf("F,%s,%s,%.1f,%d,%.0f", OUTFALL_ID, NAMES[mode], rain, turb, level);
    LoRa.endPacket();
    lastSend = millis();
  }
  delay(500);
}
