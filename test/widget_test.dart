import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tape_measure/constants/ar_constants.dart';
import 'package:tape_measure/utils/measurement_utils.dart';
import 'package:tape_measure/widgets/ar_overlay_widgets.dart';
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

    test('calculate3DDistance with negative coordinates', () {
      final p1 = vm.Vector3(-1, -1, -1);
      final p2 = vm.Vector3(1, 1, 1);

      final distance = MeasurementUtils.calculate3DDistance(p1, p2);
      expect(distance, closeTo(3.464, 0.001)); // 2 * sqrt(3)
    });

    test('calculate3DDistance with same point should return 0', () {
      final p1 = vm.Vector3(5, 5, 5);
      final p2 = vm.Vector3(5, 5, 5);

      final distance = MeasurementUtils.calculate3DDistance(p1, p2);
      expect(distance, 0.0);
    });

    test('metersToCm should convert correctly', () {
      expect(MeasurementUtils.metersToCm(1), 100);
      expect(MeasurementUtils.metersToCm(0.5), 50);
      expect(MeasurementUtils.metersToCm(0), 0);
      expect(MeasurementUtils.metersToCm(0.01), 1);
    });

    test('metersToMm should convert correctly', () {
      expect(MeasurementUtils.metersToMm(1), 1000);
      expect(MeasurementUtils.metersToMm(0.1), 100);
      expect(MeasurementUtils.metersToMm(0), 0);
      expect(MeasurementUtils.metersToMm(0.001), 1);
    });

    test('metersToInch should convert correctly', () {
      expect(MeasurementUtils.metersToInch(1), closeTo(39.37, 0.01));
      expect(MeasurementUtils.metersToInch(0.0254), closeTo(1.0, 0.01));
      expect(MeasurementUtils.metersToInch(0), 0);
    });

    test('formatDistance should format correctly', () {
      expect(MeasurementUtils.formatDistance(0.005), '5.0 mm');
      expect(MeasurementUtils.formatDistance(0.15), '15.00 cm');
      expect(MeasurementUtils.formatDistance(1.5), '1.50 m');
    });

    test('formatDistance edge cases', () {
      expect(MeasurementUtils.formatDistance(0.01), '1.00 cm');
      expect(MeasurementUtils.formatDistance(1.0), '1.00 m');
      expect(MeasurementUtils.formatDistance(0.001), '1.0 mm');
    });
  });

  group('MeasurementState', () {
    test('should have correct messages for each state', () {
      expect(MeasurementState.searching.message, '평면을 찾는 중...');
      expect(MeasurementState.scanning.message, '평면을 찾는 중... 핸드폰을 천천히 움직이세요');
      expect(MeasurementState.planeDetected.message, '평면 감지됨! 측정할 첫 번째 점을 탭하세요');
      expect(MeasurementState.firstPointSet.message, '두 번째 점을 탭하세요');
      expect(MeasurementState.measurementComplete.message, '측정 완료! 다시 탭하면 새로 측정');
      expect(MeasurementState.readyToMeasure.message, '첫 번째 점을 탭하세요');
    });

    test('should have all expected states', () {
      expect(MeasurementState.values.length, 6);
    });
  });

  group('ARConstants', () {
    test('should have correct sphere radius', () {
      expect(ARConstants.sphereRadius, 0.01); // 1cm
    });

    test('should have correct line radius', () {
      expect(ARConstants.lineRadius, 0.002); // 2mm
    });

    test('should have correct text properties', () {
      expect(ARConstants.textExtrusionDepth, 0.002);
      expect(ARConstants.textScale, 0.005);
      expect(ARConstants.textOffsetY, 0.05);
    });

    test('should have correct colors', () {
      expect(ARConstants.startPointColor, Colors.green);
      expect(ARConstants.endPointColor, Colors.red);
      expect(ARConstants.lineColor, Colors.red);
      expect(ARConstants.textColor, Colors.white);
    });

    test('should have correct metallic value', () {
      expect(ARConstants.metallic, 0.5);
    });
  });

  group('Overlay Widgets', () {
    testWidgets('StatusMessageOverlay displays message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                StatusMessageOverlay(message: '테스트 메시지'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('테스트 메시지'), findsOneWidget);
    });

    testWidgets('MeasurementResultOverlay displays distance in multiple units',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                MeasurementResultOverlay(distanceInMeters: 0.5), // 50cm
              ],
            ),
          ),
        ),
      );

      expect(find.text('50.00 cm'), findsOneWidget);
      expect(find.textContaining('500.0 mm'), findsOneWidget);
      expect(find.textContaining('inch'), findsOneWidget);
    });

    testWidgets('InstructionOverlay displays default instruction',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                InstructionOverlay(),
              ],
            ),
          ),
        ),
      );

      expect(find.text('평면 위의 두 점을 탭하여 거리를 측정하세요'), findsOneWidget);
    });

    testWidgets('InstructionOverlay displays custom instruction',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                InstructionOverlay(instruction: '커스텀 안내'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('커스텀 안내'), findsOneWidget);
    });

    testWidgets('CrosshairOverlay displays crosshair icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CrosshairOverlay(),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('ARRulerAppBar displays title and refresh button',
        (tester) async {
      bool resetCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ARRulerAppBar(
              onReset: () {
                resetCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('📏 AR 줄자'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      expect(resetCalled, true);
    });
  });
}
