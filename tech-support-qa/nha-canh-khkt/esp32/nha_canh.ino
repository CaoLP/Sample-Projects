// NHÀ CANH - firmware ESP32-S3 (Arduino IDE, board "ESP32S3 Dev Module").
// Thư viện: "DHT sensor library" + "Adafruit Unified Sensor", "OneWire", "DallasTemperature".
// ESP32 mở HTTP server, app Android gọi http://<IP>/api để lấy JSON.
#include <WiFi.h>
#include <WebServer.h>
#include <Wire.h>
#include <DHT.h>
#include <OneWire.h>
#include <DallasTemperature.h>

const char* WIFI_SSID = "TEN_WIFI";
const char* WIFI_PASS = "MAT_KHAU";

// Chân theo bảng trong tài liệu - kiểm tra lại với board thật trước khi đấu dây.
const int PIN_MQ2 = 4, PIN_DHT = 5, PIN_DS = 6, PIN_PIR = 7, PIN_WATER = 8,
          PIN_SOUND = 9, PIN_LIGHT = 10, PIN_LINE = 11, PIN_SDA = 12, PIN_SCL = 13;
const uint8_t MPU_ADDR = 0x68;  // MPU6050

DHT dht(PIN_DHT, DHT22);
OneWire oneWire(PIN_DS);
DallasTemperature ds(&oneWire);
WebServer server(80);

float temp = NAN, hum = NAN, tempDs = NAN, mpuDev = 0;
int mq2 = 0, water = 0;
unsigned long lastRead = 0;

int readAvg(int pin) {  // trung bình 16 lần để lọc nhiễu
  long s = 0;
  for (int i = 0; i < 16; i++) s += analogRead(pin);
  return s / 16;
}

// Độ lệch của |gia tốc| so với 1g: ~0 khi đứng yên, tăng khi rung/nghiêng/va chạm
float mpuDeviation() {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x3B);
  if (Wire.endTransmission(false) != 0) return 0;
  if (Wire.requestFrom(MPU_ADDR, (uint8_t)6) != 6) return 0;
  float a[3];
  for (int i = 0; i < 3; i++) {
    int hi = Wire.read(), lo = Wire.read();
    a[i] = (int16_t)((hi << 8) | lo) / 16384.0;
  }
  return fabs(sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]) - 1.0);
}

String num(float v) { return isnan(v) ? "null" : String(v, 1); }

void handleApi() {
  String j = "{\"t\":" + num(temp) + ",\"h\":" + num(hum) + ",\"td\":" + num(tempDs) +
             ",\"mq\":" + String(mq2) + ",\"water\":" + String(water) +
             ",\"mpu\":" + String(mpuDev, 2) +
             ",\"pir\":" + String(digitalRead(PIN_PIR)) +
             ",\"snd\":" + String(digitalRead(PIN_SOUND)) +
             ",\"light\":" + String(digitalRead(PIN_LIGHT)) +
             ",\"line\":" + String(digitalRead(PIN_LINE)) + "}";
  server.send(200, "application/json", j);
}

void setup() {
  Serial.begin(115200);
  pinMode(PIN_PIR, INPUT);
  pinMode(PIN_SOUND, INPUT);
  pinMode(PIN_LIGHT, INPUT);
  pinMode(PIN_LINE, INPUT);
  Wire.begin(PIN_SDA, PIN_SCL);
  Wire.beginTransmission(MPU_ADDR);  // đánh thức MPU6050
  Wire.write(0x6B);
  Wire.write(0);
  Wire.endTransmission();
  dht.begin();
  ds.begin();

  WiFi.begin(WIFI_SSID, WIFI_PASS);
  while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); }
  Serial.print("\nIP: ");
  Serial.println(WiFi.localIP());  // nhập IP này vào app
  server.on("/api", handleApi);
  server.begin();
}

void loop() {
  server.handleClient();
  if (millis() - lastRead >= 2000) {  // DHT22 cần >= 2 giây giữa 2 lần đọc
    lastRead = millis();
    temp = dht.readTemperature();
    hum = dht.readHumidity();
    ds.requestTemperatures();
    float t = ds.getTempCByIndex(0);
    tempDs = (t == DEVICE_DISCONNECTED_C) ? NAN : t;
    mq2 = readAvg(PIN_MQ2);
    water = readAvg(PIN_WATER);
    mpuDev = mpuDeviation();
  }
}
