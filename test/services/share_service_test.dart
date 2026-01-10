import 'package:flutter_test/flutter_test.dart';
import 'package:tape_measure/models/measurement_record.dart';
import 'package:tape_measure/services/share_service.dart';

void main() {
  group('ShareService', () {
    test('should have shareRecord method', () {
      expect(ShareService.shareRecord, isA<Function>());
    });

    test('should have shareMultipleRecords method', () {
      expect(ShareService.shareMultipleRecords, isA<Function>());
    });

    test('should format single record for sharing', () {
      final record = MeasurementRecord(
        id: '1',
        distanceInMeters: 1.5,
        timestamp: DateTime(2026, 1, 8, 10, 30),
        label: '거실 길이',
      );

      final text = ShareService.formatRecordText(record);
      expect(text, contains('150.00 cm'));
      expect(text, contains('거실 길이'));
    });

    test('should format record without label', () {
      final record = MeasurementRecord(
        id: '1',
        distanceInMeters: 0.5,
        timestamp: DateTime(2026, 1, 8, 10, 30),
      );

      final text = ShareService.formatRecordText(record);
      expect(text, contains('50.00 cm'));
    });

    test('should format multiple records for sharing', () {
      final records = [
        MeasurementRecord(
          id: '1',
          distanceInMeters: 1.0,
          timestamp: DateTime(2026, 1, 8, 10, 0),
          label: '측정1',
        ),
        MeasurementRecord(
          id: '2',
          distanceInMeters: 2.0,
          timestamp: DateTime(2026, 1, 8, 11, 0),
          label: '측정2',
        ),
      ];

      final text = ShareService.formatMultipleRecordsText(records);
      expect(text, contains('측정1'));
      expect(text, contains('측정2'));
      expect(text, contains('100.00 cm'));
      expect(text, contains('200.00 cm'));
    });
  });
}
