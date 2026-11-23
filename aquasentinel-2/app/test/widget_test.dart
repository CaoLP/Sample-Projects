import 'package:flutter_test/flutter_test.dart';
import 'package:aquasentinel_app/state.dart';

void main() {
  test('AI classify + flood risk match classify.py', () {
    expect(classify(300, 90, 8, 15, 14, 280, 30), 'runoff');
    expect(classify(1200, 60, 0, 0, 2, 280, 30), 'suspect');
    expect(classify(290, 32, 0, 0, 10, 280, 30), 'normal');
    expect(floodRisk(60, 180, 15, 12, 80), 2);
    expect(floodRisk(0, 100, 0, 0, 10), 0);
  });
}
