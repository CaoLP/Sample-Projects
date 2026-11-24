// Thuyen vot rac - thu dong co qua 2 module L298N (ESP32 DevKit V1, Arduino core 3.x)
// L298N #1: 2 banh guong (A = trai, B = phai). L298N #2: bang tai (kenh A).
// Ca 2 module GIU jumper ENA/ENB (chay full enable), PWM thang vao chan IN -> chi can 6 chan.
// Tranh chan LoRa (5,18,19,23,14,26), GPS (16,17), I2C (21,22) cua cac giai doan sau.
// Lenh qua Serial 115200: w tien, s lui, a trai, d phai, x dung, b bat/tat bang tai, 1..9 toc do.

const int L_IN1 = 25, L_IN2 = 27;   // guong trai  -> L298N#1 IN1, IN2
const int R_IN1 = 32, R_IN2 = 33;   // guong phai  -> L298N#1 IN3, IN4
const int B_IN1 = 4,  B_IN2 = 13;   // bang tai    -> L298N#2 IN1, IN2
const int PINS[] = {L_IN1, L_IN2, R_IN1, R_IN2, B_IN1, B_IN2};

int spd = 160;            // 0..255
bool belt = false;
unsigned long lastCmd = 0;
const unsigned long FAILSAFE_MS = 1500;  // mat lenh qua lau -> dung guong (an toan)

// v: -255..255. Duong = tien.
void motor(int in1, int in2, int v) {
  v = constrain(v, -255, 255);
  ledcWrite(in1, v > 0 ? v : 0);
  ledcWrite(in2, v < 0 ? -v : 0);
}
void drive(int l, int r) { motor(L_IN1, L_IN2, l); motor(R_IN1, R_IN2, r); }

// Tang toc dan de khong sut ap pin / reset ESP32 khi motor khoi dong
void softBelt(bool on) {
  for (int v = on ? 0 : 200; on ? v <= 200 : v >= 0; v += on ? 10 : -10) { motor(B_IN1, B_IN2, v); delay(30); }
}

void setup() {
  Serial.begin(115200);
  for (int p : PINS) { ledcAttach(p, 1000, 8); ledcWrite(p, 0); }  // 1 kHz, 8 bit
  Serial.println("w/s/a/d/x, b = bang tai, 1..9 = toc do");
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
      default: if (c >= '1' && c <= '9') spd = (c - '0') * 28;
    }
    Serial.printf("cmd=%c spd=%d belt=%d\n", c, spd, belt);
  }
  if (millis() - lastCmd > FAILSAFE_MS) drive(0, 0);
}
