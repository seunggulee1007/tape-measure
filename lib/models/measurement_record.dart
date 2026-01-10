import '../utils/measurement_utils.dart';

/// 측정 기록 모델
class MeasurementRecord {
  final String id;
  final double distanceInMeters;
  final DateTime timestamp;
  final String? label;

  MeasurementRecord({
    required this.id,
    required this.distanceInMeters,
    required this.timestamp,
    this.label,
  });

  /// cm 단위 거리
  double get distanceInCm => MeasurementUtils.metersToCm(distanceInMeters);

  /// mm 단위 거리
  double get distanceInMm => MeasurementUtils.metersToMm(distanceInMeters);

  /// inch 단위 거리
  double get distanceInInch => MeasurementUtils.metersToInch(distanceInMeters);

  /// 포맷된 거리 문자열
  String get formattedDistance =>
      MeasurementUtils.formatDistance(distanceInMeters);

  /// JSON으로 변환
  Map<String, dynamic> toJson() => {
        'id': id,
        'distanceInMeters': distanceInMeters,
        'timestamp': timestamp.toIso8601String(),
        'label': label,
      };

  /// JSON에서 생성
  factory MeasurementRecord.fromJson(Map<String, dynamic> json) {
    return MeasurementRecord(
      id: json['id'] as String,
      distanceInMeters: (json['distanceInMeters'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      label: json['label'] as String?,
    );
  }
}
