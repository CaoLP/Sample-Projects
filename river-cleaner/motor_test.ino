// Thuyen vot rac - thu dong co bang linh kien co san (ESP32 DevKit, Arduino core 3.x)
// L298N: 2 chan vit trai/phai (dao chieu duoc -> lai vi sai, lui).
// Module MOSFET 2 kenh (chi bat/tat + PWM 1 chieu): kenh 1 bang tai, kenh 2 coi/den/bom.
// L298N giu jumper ENA/ENB, PWM thang vao IN. Tranh chan LoRa (5,18,19,23,14,26), GPS (16,17), I2C (21,22).
// Lenh Serial 115200: w tien, s lui, a trai, d phai, x dung, b bang tai, h coi, 1..9 toc do, 0 = gioi han 6V.

const int L_IN1 = 25, L_IN2 = 27;   // chan vit trai  -> L298N IN1, IN2
const int R_IN1 = 32, R_IN2 = 33;   // chan vit phai  -> L298N IN3, IN4
const int BELT  = 4;                // MOSFET kenh 1 (PWM/TRIG 1) -> motor bang tai
const int AUX   = 13;               // MOSFET kenh 2 (PWM/TRIG 2) -> coi / den / bom
const int PINS[] = {L_IN1, L_IN2, R_IN1, R_IN2, BELT, AUX};

int spd = 160;            // 0..255
int maxDuty = 255;        // motor chan vit 6V chay nguon 12V: dat ~150 (L298N sut ~2V -> ~6V tren motor)
bool belt = false, aux = false;
unsigned long lastCmd = 0;
const unsigned long FAILSAFE_MS = 1500;  // mat lenh qua lau -> dung chan vit (an toan)

void motor(int in1, int in2, int v) {   // v: -255..255, duong = tien
  v = constrain(v, -maxDuty, maxDuty);
  ledcWrite(in1, v > 0 ? v : 0);
  ledcWrite(in2, v < 0 ? -v : 0);
}
void drive(int l, int r) { motor(L_IN1, L_IN2, l); motor(R_IN1, R_IN2, r); }

// Tang toc dan: tranh sut ap lam ESP32 reset khi motor bang tai khoi dong
void softBelt(bool on) {
  for (int i = 0; i <= 20; i++) { ledcWrite(BELT, (on ? i : 20 - i) * 10); delay(30); }
}

void setup() {
  Serial.begin(115200);
  for (int p : PINS) { ledcAttach(p, 1000, 8); ledcWrite(p, 0); }  // 1 kHz, 8 bit
  Serial.println("w/s/a/d/x, b = bang tai, h = coi, 1..9 = toc do, 0 = gioi han 6V");
}

void loop() {
  if (Serial.available()) {
    char c = Serial.read();
    lastCmd = millis();
    switch (c) {
      case 'w': drive(spd, spd); break;
      case 's': drive(-spd, -spd); break;
      case 'a': drive(-spd / 2, spd); break;
      case 'd': drive(spd, -spd / 2); break;
      case 'x': drive(0, 0); break;
      case 'b': belt = !belt; softBelt(belt); break;
      case 'h': aux = !aux; ledcWrite(AUX, aux ? 255 : 0); break;
      case '0': maxDuty = maxDuty == 255 ? 150 : 255; break;
      default: if (c >= '1' && c <= '9') spd = (c - '0') * 28;
    }
    Serial.printf("cmd=%c spd=%d max=%d belt=%d aux=%d\n", c, spd, maxDuty, belt, aux);
  }
  if (millis() - lastCmd > FAILSAFE_MS) drive(0, 0);
}
