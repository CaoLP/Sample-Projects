import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'i18n.dart';

// Ngưỡng nghiên cứu (giống MainActivity.kt) – phải chỉnh theo đo thực tế. ADC 0..4095.
const mqDelta = 400, tempMax = 50.0, humMax = 85.0, waterMax = 3000, mpuMax = 0.5;

class Reading {
  final double t, h, td, mpu;
  final int mq, water;
  final bool pir, snd, light, line;
  const Reading(this.t, this.h, this.td, this.mq, this.water, this.mpu, this.pir, this.snd, this.light, this.line);
  // JSON từ firmware nha_canh.ino: GET http://<IP>/api
  factory Reading.fromJson(Map<String, dynamic> j) {
    double d(String k) => (j[k] as num?)?.toDouble() ?? double.nan;
    int i(String k) => (j[k] as num?)?.toInt() ?? 0;
    return Reading(d('t'), d('h'), d('td'), i('mq'), i('water'), d('mpu'), i('pir') == 1, i('snd') == 1, i('light') == 1, i('line') == 1);
  }
}

/// Trả về mã cảnh báo (khoá i18n) – logic giống alertsOf() bản Kotlin.
List<String> alertsOf(Reading r, int mqBase, bool away) => [
      if (r.mq - mqBase > mqDelta) 'aGas',
      if (r.t > tempMax || r.td > tempMax) 'aTemp',
      if (r.h > humMax) 'aHum',
      if (r.water > waterMax) 'aWater',
      if (r.mpu > mpuMax) 'aMpu',
      if (away && r.pir && r.snd) 'aIntruder',
    ];

class LogEntry {
  final DateTime at;
  final String kind, text; // kind: alert | note | info
  LogEntry(this.at, this.kind, this.text);
  Map<String, dynamic> toJson() => {'at': at.millisecondsSinceEpoch, 'k': kind, 't': text};
  static LogEntry fromJson(Map<String, dynamic> j) => LogEntry(DateTime.fromMillisecondsSinceEpoch(j['at']), j['k'], j['t']);
}

class AppState extends ChangeNotifier {
  bool demo = true, away = false, dark = false, notify = true, online = true;
  String ip = '192.168.1.50';
  Reading? r;
  int mqBase = -1;
  final _calib = <int>[];
  final _lastFired = <String, DateTime>{};
  final hist = <Reading>[];
  List<String> alerts = [];
  final log = <LogEntry>[];
  Uint8List? photo;
  Timer? _timer;
  int _tick = 0;
  final _rnd = Random();
  SharedPreferences? _sp;
  final _notif = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    _sp = await SharedPreferences.getInstance();
    ip = _sp!.getString('ip') ?? ip;
    demo = _sp!.getBool('demo') ?? true;
    dark = _sp!.getBool('dark') ?? false;
    lang = _sp!.getString('lang') ?? 'vi';
    log.addAll((jsonDecode(_sp!.getString('log') ?? '[]') as List).map((e) => LogEntry.fromJson(e)));
    if (!kIsWeb) {
      await _notif.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
      await _notif.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }
    _restart();
    notifyListeners();
  }

  void _restart() {
    _timer?.cancel();
    mqBase = -1;
    _calib.clear();
    hist.clear();
    _tick = 0;
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  // Kịch bản mô phỏng ~2 phút: bình thường → khói bếp → nước dâng → (vắng nhà) có người lạ.
  Reading _fake() {
    final t = _tick++ % 60, n = _rnd.nextDouble();
    final smoke = t >= 15 && t < 22, flood = t >= 30 && t < 38, intr = t >= 45 && t < 49;
    return Reading(
      28 + n * 2 + (smoke ? 6 : 0), 62 + n * 6 + (flood ? 20 : 0), 27 + n * 1.5,
      smoke ? 900 + _rnd.nextInt(300) : 300 + _rnd.nextInt(60),
      flood ? 3100 + _rnd.nextInt(400) : 900 + _rnd.nextInt(200),
      intr ? .6 + n * .3 : n * .08,
      intr || _rnd.nextInt(10) == 0, intr || _rnd.nextInt(12) == 0, _rnd.nextBool(), false,
    );
  }

  Future<void> _poll() async {
    try {
      final x = demo ? _fake() : await fetch();
      online = true;
      r = x;
      hist.add(x);
      if (hist.length > 60) hist.removeAt(0);
      if (mqBase < 0) {
        _calib.add(x.mq);
        if (_calib.length >= 10) mqBase = _calib.reduce((a, b) => a + b) ~/ _calib.length;
      }
      // Kịch bản demo luôn hiện "người lạ" để giám khảo xem được, không cần bật vắng nhà.
      final a = alertsOf(x, mqBase >= 0 ? mqBase : x.mq, away || demo);
      // Cảm biến dao động quanh ngưỡng: cùng 1 cảnh báo chỉ báo lại sau 2 phút.
      final now = DateTime.now();
      for (final k in a.where((k) => !alerts.contains(k))) {
        if (now.difference(_lastFired[k] ?? DateTime(2000)).inMinutes < 2) continue;
        _lastFired[k] = now;
        _add('alert', k);
        _push(tr(k));
      }
      alerts = a;
    } catch (_) {
      online = false;
    }
    notifyListeners();
  }

  Future<Reading> fetch() async {
    final res = await http.get(Uri.parse('http://$ip/api')).timeout(const Duration(seconds: 2));
    return Reading.fromJson(jsonDecode(res.body));
  }

  void _push(String text) {
    HapticFeedback.heavyImpact();
    if (kIsWeb || !notify) return;
    _notif.show(_rnd.nextInt(1 << 30), tr('app'), text,
        const NotificationDetails(android: AndroidNotificationDetails('nhacanh', 'Cảnh báo NHÀ CANH', importance: Importance.max, priority: Priority.high)));
  }

  void _add(String kind, String text) {
    log.insert(0, LogEntry(DateTime.now(), kind, text));
    if (log.length > 200) log.removeLast();
    _sp?.setString('log', jsonEncode(log.map((e) => e.toJson()).toList()));
  }

  void addNote(String s) { _add('note', s); notifyListeners(); }
  void setPhoto(Uint8List b) { photo = b; _add('info', 'photoSaved'); notifyListeners(); }
  void clearLog() { log.clear(); _sp?.setString('log', '[]'); notifyListeners(); }
  void setAway(bool v) { away = v; _add('info', v ? 'awayLog' : 'homeLog'); notifyListeners(); }
  void setDemo(bool v) { demo = v; _sp?.setBool('demo', v); _restart(); }
  void setIp(String v) { ip = v.trim(); _sp?.setString('ip', ip); if (!demo) _restart(); }
  void setDark(bool v) { dark = v; _sp?.setBool('dark', v); notifyListeners(); }
  void setLang(String v) { lang = v; _sp?.setString('lang', v); notifyListeners(); }
  void setNotify(bool v) { notify = v; notifyListeners(); }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
}
