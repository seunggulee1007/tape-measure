import 'package:flutter_test/flutter_test.dart';
import 'package:tape_measure/models/measurement_record.dart';
import 'package:tape_measure/services/measurement_history_service.dart';

void main() {
  group('MeasurementHistoryService', () {
    late MeasurementHistoryService service;

    setUp(() {
      service = MeasurementHistoryService();
    });

    test('should start with empty history', () {
      expect(service.records, isEmpty);
    });

    test('should add record to history', () {
      final record = MeasurementRecord(
        id: '1',
        distanceInMeters: 1.5,
        timestamp: DateTime.now(),
      );

      service.addRecord(record);
      expect(service.records.length, 1);
      expect(service.records.first.id, '1');
    });

    test('should remove record from history', () {
      final record = MeasurementRecord(
        id: '1',
        distanceInMeters: 1.5,
        timestamp: DateTime.now(),
      );

      service.addRecord(record);
      service.removeRecord('1');
      expect(service.records, isEmpty);
    });

    test('should clear all records', () {
      service.addRecord(MeasurementRecord(
        id: '1',
        distanceInMeters: 1.5,
        timestamp: DateTime.now(),
      ));
      service.addRecord(MeasurementRecord(
        id: '2',
        distanceInMeters: 2.0,
        timestamp: DateTime.now(),
      ));

      service.clearAll();
      expect(service.records, isEmpty);
    });

    test('should get record by id', () {
      final record = MeasurementRecord(
        id: '1',
        distanceInMeters: 1.5,
        timestamp: DateTime.now(),
      );

      service.addRecord(record);
      final found = service.getRecordById('1');
      expect(found?.distanceInMeters, 1.5);
    });

    test('should return null for non-existent id', () {
      final found = service.getRecordById('non-existent');
      expect(found, isNull);
    });

    test('should get records in reverse chronological order', () {
      service.addRecord(MeasurementRecord(
        id: '1',
        distanceInMeters: 1.0,
        timestamp: DateTime(2026, 1, 1),
      ));
      service.addRecord(MeasurementRecord(
        id: '2',
        distanceInMeters: 2.0,
        timestamp: DateTime(2026, 1, 2),
      ));

      final records = service.records;
      expect(records.first.id, '2'); // 최신이 먼저
      expect(records.last.id, '1');
    });

    test('should update record label', () {
      service.addRecord(MeasurementRecord(
        id: '1',
        distanceInMeters: 1.5,
        timestamp: DateTime.now(),
      ));

      service.updateLabel('1', '거실 길이');
      expect(service.getRecordById('1')?.label, '거실 길이');
    });
  });
}
