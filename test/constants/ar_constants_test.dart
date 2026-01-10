import 'package:flutter_test/flutter_test.dart';
import 'package:tape_measure/constants/ar_constants.dart';

void main() {
  group('PlaneDetectionMode', () {
    test('should have all expected modes', () {
      expect(PlaneDetectionMode.values.length, 3);
    });

    test('should have horizontal mode', () {
      expect(PlaneDetectionMode.horizontal.label, '수평면');
    });

    test('should have vertical mode', () {
      expect(PlaneDetectionMode.vertical.label, '수직면');
    });

    test('should have both mode', () {
      expect(PlaneDetectionMode.both.label, '모든 평면');
    });
  });
}
