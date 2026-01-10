import 'package:flutter_test/flutter_test.dart';
import 'package:tape_measure/services/haptic_service.dart';

void main() {
  group('HapticService', () {
    test('should have lightImpact method', () {
      expect(HapticService.lightImpact, isA<Function>());
    });

    test('should have mediumImpact method', () {
      expect(HapticService.mediumImpact, isA<Function>());
    });

    test('should have heavyImpact method', () {
      expect(HapticService.heavyImpact, isA<Function>());
    });

    test('should have vibrate method', () {
      expect(HapticService.vibrate, isA<Function>());
    });
  });
}
