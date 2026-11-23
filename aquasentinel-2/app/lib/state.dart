import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'mqtt_factory.dart';
import 'i18n.dart';

/// AI 1 — giống classify.py: phân biệt nước mưa chảy tràn / nghi xả thải.
String classify(double tds, double turb, double riseCmH, double rainMmH, int hour, double tdsBase, double turbBase) {
  final tj = tds / max(tdsBase, 1), uj = turb / max(turbBase, 1);
  final raining = rainMmH >= 2, night = hour >= 22 || hour < 5;
  if (raining && riseCmH > 5 && uj > 1.5 && tj < 1.5) return 'runoff';
  if (!raining && (tj > 2 || uj > 3)) return night || tj > 3 ? 'suspect' : 'watch';
  if (raining && tj > 2.5) return 'suspect';
  return 'normal';
}

/// AI 2 — điểm nguy cơ ngập 0..2.
int floodRisk(double rain3h, double tideCm, double depthCm, double riseCmH, double trapPct) {
  final s = rain3h / 30 + max(tideCm - 150, 0) / 50 + depthCm / 20 + riseCmH / 10 + trapPct / 100;
  return s >= 3 ? 2 : s >= 1.5 ? 1 : 0;
}

class Beacon {
  final String id, name;
  final Offset pos; // toạ độ chuẩn hoá 0..1 trên bản đồ
  double depth;
  bool sos = false;
  Beacon(this.id, this.name, this.pos, this.depth);
  int get level => depth >= 30 ? 2 : depth >= 10 ? 1 : 0;
}

class Alert {
  final String kind, title; // kind: flood | pollution | cleanup | sos
  final int sev;
  final DateTime at;
  Alert(this.kind, this.title, this.sev, this.at);
}

class AppState extends ChangeNotifier {
  bool officer = false, dark = false, live = false;
  String mqttHost = 'broker.hivemq.com', mqttTopic = 'enviguard/sensor';
  double temp = 28.4, tds = 285, turb = 30, flow = 12.5, depth = 42, rain = 0, ph = 7.1;
  double rain3h = 8, tide = 120, trapPct = 35, rise = 0;
  bool valveOpen = false;
  int greenPoints = 1240;
  final hist = <String, List<double>>{'tds': [], 'turb': [], 'depth': [], 'temp': []};
  final beacons = [
    Beacon('B01', 'Hẻm 12 Lê Duẩn', const Offset(.30, .42), 0),
    Beacon('B02', 'Chợ Tam Xuân', const Offset(.62, .30), 0),
    Beacon('B03', 'Trường TH Kim Đồng', const Offset(.48, .66), 0),
    Beacon('B04', 'Ngã tư Phan Châu Trinh', const Offset(.78, .58), 0),
  ];
  final alerts = <Alert>[];
  String _lastAi = 'normal';
  MqttClient? _mqtt;
  Timer? _sim;
  int _tick = 0;
  final _rnd = Random(7);

  String get ai => classify(tds, turb, rise, rain, DateTime.now().hour, 280, 30);
  int get risk => floodRisk(rain3h, tide, beacons.map((b) => b.depth).reduce(max), rise, trapPct);

  AppState() {
    for (var i = 0; i < 48; i++) {
      _push(280 + _rnd.nextDouble() * 20, 28 + _rnd.nextDouble() * 6, 40 + sin(i / 6) * 4, 27 + sin(i / 8) * 1.5);
    }
    alerts.addAll([
      Alert('cleanup', 'Bẫy rác cống Lê Duẩn đầy 72%', 1, DateTime.now().subtract(const Duration(hours: 3))),
      Alert('pollution', 'TDS tăng 2.4 lần lúc 02:10 — đã lấy mẫu', 2, DateTime.now().subtract(const Duration(hours: 9))),
      Alert('flood', 'Hẻm 12 Lê Duẩn ngập 18cm', 1, DateTime.now().subtract(const Duration(days: 1))),
    ]);
    _sim = Timer.periodic(const Duration(seconds: 2), (_) => _simulate());
  }

  void _push(double a, double b, double c, double d) {
    void add(String k, double v) {
      final l = hist[k]!..add(v);
      if (l.length > 48) l.removeAt(0);
    }
    add('tds', a); add('turb', b); add('depth', c); add('temp', d);
  }

  // Kịch bản demo 2 phút: khô → mưa lớn → ngập → rút → đêm xả thải lén → bình thường.
  void _simulate() {
    if (live) return;
    _tick = (_tick + 1) % 60;
    final t = _tick;
    final storm = t >= 8 && t < 30;
    rain = storm ? 18 + _rnd.nextDouble() * 10 : max(0, rain - 4);
    rain3h = storm ? 55 : t < 8 ? 8 + t * 5.0 : 5;
    rise = storm ? 9 + _rnd.nextDouble() * 4 : -2;
    turb = storm ? 85 + _rnd.nextDouble() * 20 : t >= 40 && t < 46 ? 105 : 30 + _rnd.nextDouble() * 4;
    tds = storm ? 240 + _rnd.nextDouble() * 15 : t >= 40 && t < 46 ? 950 + _rnd.nextDouble() * 80 : 282 + _rnd.nextDouble() * 10;
    depth = (depth + rise * .2).clamp(38, 75);
    temp = 28 + _rnd.nextDouble();
    flow = 10 + rain * .6 + _rnd.nextDouble();
    ph = t >= 40 && t < 46 ? 5.9 : 7 + _rnd.nextDouble() * .3;
    trapPct = (trapPct + (storm ? 2.5 : .2)).clamp(0, 100);
    valveOpen = storm && t < 16; // 15-20 phút đầu cơn mưa (tua nhanh)
    for (final b in beacons) {
      final k = b.id == 'B01' ? 1.6 : b.id == 'B03' ? 1.2 : b.id == 'B02' ? .8 : .5;
      b.depth = (b.depth + (storm ? 2.2 * k : -3)).clamp(0, 60);
    }
    _apply();
  }

  void _apply() {
    _push(tds, turb, depth, temp);
    final a = ai;
    if (a != _lastAi && (a == 'suspect' || a == 'runoff')) {
      alerts.insert(0, Alert(a == 'suspect' ? 'pollution' : 'flood', tr(a), a == 'suspect' ? 2 : 1, DateTime.now()));
    }
    _lastAi = a;
    for (final b in beacons) {
      if (b.level == 2 && !alerts.take(5).any((x) => x.title.contains(b.name))) {
        alerts.insert(0, Alert('flood', '${b.name} ngập ${b.depth.toStringAsFixed(0)}cm', 2, DateTime.now()));
      }
    }
    if (trapPct > 60 && rain3h > 30 && !alerts.take(5).any((x) => x.kind == 'cleanup')) {
      alerts.insert(0, Alert('cleanup', 'Sắp mưa lớn + bẫy rác ${trapPct.toStringAsFixed(0)}% → dọn cống', 1, DateTime.now()));
    }
    if (alerts.length > 60) alerts.removeLast();
    notifyListeners();
  }

  void dispatchCleanup() {
    trapPct = 5;
    greenPoints += 50;
    alerts.insert(0, Alert('cleanup', tr('dispatched'), 0, DateTime.now()));
    notifyListeners();
  }

  void broadcast() {
    alerts.insert(0, Alert('flood', tr('broadcasted'), 1, DateTime.now()));
    notifyListeners();
  }

  void sos(Beacon b) {
    b.sos = true;
    alerts.insert(0, Alert('sos', 'SOS ${b.name} — ${b.depth.toStringAsFixed(0)}cm', 2, DateTime.now()));
    notifyListeners();
  }

  void toggleDark() { dark = !dark; notifyListeners(); }
  void setLang(String l) { lang = l; notifyListeners(); }

  /// Nhận JSON từ ESP32 số 2: {"temperature","tds","turbidity","flow","depth","rain","ph"}
  void applyPayload(Map<String, dynamic> d) {
    double g(String k, double def) => (d[k] as num?)?.toDouble() ?? def;
    final old = depth;
    temp = g('temperature', temp); tds = g('tds', tds); turb = g('turbidity', turb);
    flow = g('flow', flow); depth = g('depth', depth); rain = g('rain', rain); ph = g('ph', ph);
    rise = (depth - old) * 30; // mẫu ~2s/lần → cm/h ước lượng
    _apply();
  }

  Future<String?> connect() async {
    try {
      _mqtt?.disconnect();
      final c = makeClient(mqttHost, 'aqua_${DateTime.now().millisecondsSinceEpoch}');
      c.keepAlivePeriod = 30;
      await c.connect();
      c.subscribe(mqttTopic, MqttQos.atLeastOnce);
      c.updates!.listen((ev) {
        final m = ev.first.payload as MqttPublishMessage;
        try {
          applyPayload(jsonDecode(MqttPublishPayload.bytesToStringAsString(m.payload.message)));
        } catch (_) {}
      });
      c.onDisconnected = () { live = false; notifyListeners(); };
      _mqtt = c;
      live = true;
      notifyListeners();
      return null;
    } catch (e) {
      live = false;
      notifyListeners();
      return '$e';
    }
  }

  @override
  void dispose() { _sim?.cancel(); _mqtt?.disconnect(); super.dispose(); }
}
