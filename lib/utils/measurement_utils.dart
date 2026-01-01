import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as vm;

class MeasurementUtils {
  /// 두 3D 점 사이의 거리 계산 (미터)
  static double calculate3DDistance(vm.Vector3 p1, vm.Vector3 p2) {
    return sqrt(
      pow(p2.x - p1.x, 2) +
      pow(p2.y - p1.y, 2) +
      pow(p2.z - p1.z, 2)
    );
  }

  /// 미터를 센티미터로 변환
  static double metersToCm(double meters) {
    return meters * 100;
  }

  /// 미터를 밀리미터로 변환
  static double metersToMm(double meters) {
    return meters * 1000;
  }

  /// 미터를 인치로 변환
  static double metersToInch(double meters) {
    return meters * 39.3701;
  }

  /// 거리를 포맷팅된 문자열로 변환
  static String formatDistance(double meters) {
    double cm = metersToCm(meters);
    if (cm < 1) {
      return '${metersToMm(meters).toStringAsFixed(1)} mm';
    } else if (cm < 100) {
      return '${cm.toStringAsFixed(2)} cm';
    } else {
      return '${meters.toStringAsFixed(2)} m';
    }
  }
}
