// ESP32-S3 hỗ trợ người già: nút SOS / té ngã -> chụp ảnh + ghi âm 3s -> gửi server -> phát âm báo.
// Arduino-ESP32 core 3.x, board: ESP32S3 Dev Module, PSRAM: OPI PSRAM.
// Thư viện: esp32-camera (có sẵn trong core), ESP_I2S (có sẵn), Adafruit MPU6050 (tuỳ chọn).
#include <WiFi.h>
#include <HTTPClient.h>
#include "esp_camera.h"
#include "ESP_I2S.h"

const char* WIFI_SSID = "YOUR_WIFI";
const char* WIFI_PASS = "YOUR_PASS";
const char* SERVER    = "http://192.168.1.10:8000";   // server FastAPI bên dưới

// --- Chân (Freenove ESP32-S3-WROOM CAM; camera chiếm GPIO4-13,15-18; PSRAM chiếm 35-37) ---
#define PIN_SOS   1
#define PIN_LED   2    // LED onboard
#define MIC_SCK   41
#define MIC_WS    42
#define MIC_SD    40   // không dùng khe thẻ SD (38-40) khi lắp mic/MPU
#define SPK_BCLK  14
#define SPK_LRC   21
#define SPK_DIN   47

// Camera pin map của Freenove S3 CAM (giống ESP32-S3-EYE)
#define CAM_PWDN -1
#define CAM_RESET -1
#define CAM_XCLK 15
#define CAM_SIOD 4
#define CAM_SIOC 5
#define CAM_Y9 16
#define CAM_Y8 17
#define CAM_Y7 18
#define CAM_Y6 12
#define CAM_Y5 10
#define CAM_Y4 8
#define CAM_Y3 9
#define CAM_Y2 11
#define CAM_VSYNC 6
#define CAM_HREF 7
#define CAM_PCLK 13

const uint32_t SAMPLE_RATE = 16000;
const int RECORD_SEC = 3;

I2SClass mic, spk;

bool initCamera() {
  camera_config_t c = {};
  c.ledc_channel = LEDC_CHANNEL_0; c.ledc_timer = LEDC_TIMER_0;
  c.pin_d0 = CAM_Y2; c.pin_d1 = CAM_Y3; c.pin_d2 = CAM_Y4; c.pin_d3 = CAM_Y5;
  c.pin_d4 = CAM_Y6; c.pin_d5 = CAM_Y7; c.pin_d6 = CAM_Y8; c.pin_d7 = CAM_Y9;
  c.pin_xclk = CAM_XCLK; c.pin_pclk = CAM_PCLK; c.pin_vsync = CAM_VSYNC; c.pin_href = CAM_HREF;
  c.pin_sccb_sda = CAM_SIOD; c.pin_sccb_scl = CAM_SIOC; c.pin_pwdn = CAM_PWDN; c.pin_reset = CAM_RESET;
  c.xclk_freq_hz = 20000000; c.pixel_format = PIXFORMAT_JPEG;
  c.frame_size = FRAMESIZE_VGA; c.jpeg_quality = 12; c.fb_count = 1;
  c.fb_location = CAMERA_FB_IN_PSRAM; c.grab_mode = CAMERA_GRAB_LATEST;
  return esp_camera_init(&c) == ESP_OK;
}

bool initAudio() {
  mic.setPins(MIC_SCK, MIC_WS, -1, MIC_SD);
  spk.setPins(SPK_BCLK, SPK_LRC, SPK_DIN);
  return mic.begin(I2S_MODE_STD, SAMPLE_RATE, I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_MONO, I2S_STD_SLOT_LEFT) &&
         spk.begin(I2S_MODE_STD, SAMPLE_RATE, I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_MONO);
}

void beep(int freq, int ms) {                 // phát tiếng bíp qua MAX98357A
  const int n = SAMPLE_RATE * ms / 1000;
  int16_t buf[256];
  for (int i = 0; i < n; i += 256) {
    for (int j = 0; j < 256; j++) buf[j] = ((i + j) * freq * 2 / SAMPLE_RATE) % 2 ? 6000 : -6000;
    spk.write((uint8_t*)buf, sizeof(buf));
  }
}

bool postSOS(const char* reason) {
  camera_fb_t* fb = esp_camera_fb_get();
  size_t wavLen = 0;
  uint8_t* wav = mic.recordWAV(RECORD_SEC, &wavLen);   // có header WAV sẵn
  if (!fb || !wav) { if (fb) esp_camera_fb_return(fb); free(wav); return false; }

  // multipart/form-data: reason + photo.jpg + voice.wav
  String b = "----esp32sos";
  String p1 = "--" + b + "\r\nContent-Disposition: form-data; name=\"reason\"\r\n\r\n" + reason +
              "\r\n--" + b + "\r\nContent-Disposition: form-data; name=\"photo\"; filename=\"p.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n";
  String p2 = "\r\n--" + b + "\r\nContent-Disposition: form-data; name=\"voice\"; filename=\"v.wav\"\r\nContent-Type: audio/wav\r\n\r\n";
  String p3 = "\r\n--" + b + "--\r\n";
  size_t total = p1.length() + fb->len + p2.length() + wavLen + p3.length();
  uint8_t* body = (uint8_t*)ps_malloc(total);
  bool ok = false;
  if (body) {
    size_t o = 0;
    memcpy(body + o, p1.c_str(), p1.length()); o += p1.length();
    memcpy(body + o, fb->buf, fb->len);        o += fb->len;
    memcpy(body + o, p2.c_str(), p2.length()); o += p2.length();
    memcpy(body + o, wav, wavLen);             o += wavLen;
    memcpy(body + o, p3.c_str(), p3.length());
    HTTPClient http;
    http.begin(String(SERVER) + "/sos");
    http.addHeader("Content-Type", "multipart/form-data; boundary=" + b);
    int code = http.POST(body, total);
    ok = code == 200;
    Serial.printf("POST /sos -> %d\n", code);
    http.end();
    free(body);
  }
  esp_camera_fb_return(fb);
  free(wav);
  return ok;
}

void setup() {
  Serial.begin(115200);
  pinMode(PIN_SOS, INPUT_PULLUP);
  pinMode(PIN_LED, OUTPUT);
  if (!initCamera()) Serial.println("Camera init FAIL");
  if (!initAudio())  Serial.println("I2S init FAIL");
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  while (WiFi.status() != WL_CONNECTED) { delay(300); Serial.print("."); }
  Serial.println("\nWiFi OK " + WiFi.localIP().toString());
  beep(1000, 150);
}

void loop() {
  if (digitalRead(PIN_SOS) == LOW) {           // nhấn nút SOS
    delay(50);                                  // chống dội phím
    if (digitalRead(PIN_SOS) != LOW) return;
    digitalWrite(PIN_LED, HIGH);
    beep(2000, 300);                            // báo đã nhận
    bool ok = postSOS("button");
    ok ? beep(1500, 600) : (beep(400, 300), beep(400, 300));  // dài = đã gửi, 2 tiếng trầm = lỗi
    digitalWrite(PIN_LED, LOW);
    while (digitalRead(PIN_SOS) == LOW) delay(10);
  }
  // TODO té ngã: đọc MPU6050, |a| > 2.5g rồi gần 1g yên 2s -> postSOS("fall")
}
