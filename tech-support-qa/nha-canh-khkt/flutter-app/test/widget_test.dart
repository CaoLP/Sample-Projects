import 'package:flutter_test/flutter_test.dart';
import 'package:nhacanh_app/state.dart';

void main() {
  test('alertsOf matches Kotlin version', () {
    const ok = Reading(28, 60, 27, 320, 1000, .05, false, false, false, false);
    expect(alertsOf(ok, 300, false), isEmpty);
    const bad = Reading(55, 90, 27, 900, 3200, .7, true, true, false, false);
    expect(alertsOf(bad, 300, true), ['aGas', 'aTemp', 'aHum', 'aWater', 'aMpu', 'aIntruder']);
    expect(alertsOf(bad, 300, false).contains('aIntruder'), false);
    final j = Reading.fromJson({'t': 30.5, 'h': 70, 'td': 29, 'mq': 400, 'water': 1200, 'mpu': .1, 'pir': 1, 'snd': 0});
    expect([j.t, j.mq, j.pir, j.snd], [30.5, 400, true, false]);
  });
}
