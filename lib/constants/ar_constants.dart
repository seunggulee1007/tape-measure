import 'package:flutter/material.dart';

/// AR 줄자 앱에서 사용하는 상수 모음
class ARConstants {
  ARConstants._();

  // AR 오브젝트 크기
  static const double sphereRadius = 0.01; // 1cm
  static const double lineRadius = 0.002; // 2mm
  static const double textExtrusionDepth = 0.002;
  static const double textScale = 0.005;
  static const double textOffsetY = 0.05; // 선 위에 표시할 오프셋

  // 색상
  static const Color startPointColor = Colors.green;
  static const Color endPointColor = Colors.red;
  static const Color lineColor = Colors.red;
  static const Color textColor = Colors.white;

  // 머티리얼
  static const double metallic = 0.5;
}

/// 측정 상태를 나타내는 enum
enum MeasurementState {
  searching('평면을 찾는 중...'),
  scanning('평면을 찾는 중... 핸드폰을 천천히 움직이세요'),
  planeDetected('평면 감지됨! 측정할 첫 번째 점을 탭하세요'),
  firstPointSet('두 번째 점을 탭하세요'),
  measurementComplete('측정 완료! 다시 탭하면 새로 측정'),
  readyToMeasure('첫 번째 점을 탭하세요');

  final String message;
  const MeasurementState(this.message);
}
