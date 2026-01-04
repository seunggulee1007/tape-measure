import 'package:flutter_test/flutter_test.dart';
import 'package:tape_measure/utils/measurement_utils.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

void main() {
  group('MeasurementUtils', () {
    test('calculate3DDistance should return correct distance', () {
      final p1 = vm.Vector3(0, 0, 0);
      final p2 = vm.Vector3(1, 0, 0);

      final distance = MeasurementUtils.calculate3DDistance(p1, p2);
      expect(distance, 1.0);
    });

    test('calculate3DDistance with 3D points', () {
      final p1 = vm.Vector3(0, 0, 0);
      final p2 = vm.Vector3(1, 1, 1);

      final distance = MeasurementUtils.calculate3DDistance(p1, p2);
      expect(distance, closeTo(1.732, 0.001)); // sqrt(3)
    });

    test('metersToCm should convert correctly', () {
      expect(MeasurementUtils.metersToCm(1), 100);
      expect(MeasurementUtils.metersToCm(0.5), 50);
    });

    test('metersToMm should convert correctly', () {
      expect(MeasurementUtils.metersToMm(1), 1000);
      expect(MeasurementUtils.metersToMm(0.1), 100);
    });

    test('metersToInch should convert correctly', () {
      expect(MeasurementUtils.metersToInch(1), closeTo(39.37, 0.01));
    });

    test('formatDistance should format correctly', () {
      expect(MeasurementUtils.formatDistance(0.005), '5.0 mm');
      expect(MeasurementUtils.formatDistance(0.15), '15.00 cm');
      expect(MeasurementUtils.formatDistance(1.5), '1.50 m');
    });
  });
}
