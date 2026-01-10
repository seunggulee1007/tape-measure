import '../models/measurement_record.dart';

/// 측정 히스토리 관리 서비스
class MeasurementHistoryService {
  final List<MeasurementRecord> _records = [];

  /// 모든 기록 (최신순)
  List<MeasurementRecord> get records {
    final sorted = List<MeasurementRecord>.from(_records);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  /// 기록 추가
  void addRecord(MeasurementRecord record) {
    _records.add(record);
  }

  /// 기록 삭제
  void removeRecord(String id) {
    _records.removeWhere((r) => r.id == id);
  }

  /// 전체 삭제
  void clearAll() {
    _records.clear();
  }

  /// ID로 기록 조회
  MeasurementRecord? getRecordById(String id) {
    try {
      return _records.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 라벨 업데이트
  void updateLabel(String id, String label) {
    final index = _records.indexWhere((r) => r.id == id);
    if (index != -1) {
      final old = _records[index];
      _records[index] = MeasurementRecord(
        id: old.id,
        distanceInMeters: old.distanceInMeters,
        timestamp: old.timestamp,
        label: label,
      );
    }
  }
}
