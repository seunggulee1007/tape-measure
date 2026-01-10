import 'package:share_plus/share_plus.dart';
import '../models/measurement_record.dart';

/// 공유 서비스
class ShareService {
  ShareService._();

  /// 단일 기록 공유
  static Future<void> shareRecord(MeasurementRecord record) async {
    final text = formatRecordText(record);
    await SharePlus.instance.share(ShareParams(text: text, subject: 'AR 줄자 측정 결과'));
  }

  /// 여러 기록 공유
  static Future<void> shareMultipleRecords(List<MeasurementRecord> records) async {
    final text = formatMultipleRecordsText(records);
    await SharePlus.instance.share(ShareParams(text: text, subject: 'AR 줄자 측정 결과'));
  }

  /// 단일 기록 텍스트 포맷
  static String formatRecordText(MeasurementRecord record) {
    final buffer = StringBuffer();

    if (record.label != null && record.label!.isNotEmpty) {
      buffer.writeln('📏 ${record.label}');
    } else {
      buffer.writeln('📏 측정 결과');
    }

    buffer.writeln('${record.distanceInCm.toStringAsFixed(2)} cm');
    buffer.writeln('${record.distanceInMm.toStringAsFixed(1)} mm');
    buffer.writeln('${record.distanceInInch.toStringAsFixed(2)} inch');
    buffer.writeln();
    buffer.writeln('측정 시간: ${_formatDateTime(record.timestamp)}');

    return buffer.toString();
  }

  /// 여러 기록 텍스트 포맷
  static String formatMultipleRecordsText(List<MeasurementRecord> records) {
    final buffer = StringBuffer();
    buffer.writeln('📏 AR 줄자 측정 기록');
    buffer.writeln('=' * 30);
    buffer.writeln();

    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      final label = record.label ?? '측정 ${i + 1}';
      buffer.writeln('[$label]');
      buffer.writeln('${record.distanceInCm.toStringAsFixed(2)} cm');
      buffer.writeln('측정 시간: ${_formatDateTime(record.timestamp)}');
      buffer.writeln();
    }

    return buffer.toString();
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
