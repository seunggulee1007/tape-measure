import 'package:flutter_test/flutter_test.dart';
import 'package:tape_measure/models/measurement_record.dart';

void main() {
  group('MeasurementRecord', () {
    test('should create with required fields', () {
      final record = MeasurementRecord(
        id: '1',
        distanceInMeters: 1.5,
        timestamp: DateTime(2026, 1, 8, 10, 30),
      );

      expect(record.id, '1');
      expect(record.distanceInMeters, 1.5);
      expect(record.timestamp, DateTime(2026, 1, 8, 10, 30));
    });

    test('should create with optional label', () {
      final record = MeasurementRecord(
        id: '1',
        distanceInMeters: 1.5,
        timestamp: DateTime(2026, 1, 8, 10, 30),
        label: '거실 길이',
      );

      expect(record.label, '거실 길이');
    });

    test('should convert to cm correctly', () {
      final record = MeasurementRecord(
        id: '1',
        distanceInMeters: 1.5,
        timestamp: DateTime.now(),
      );

      expect(record.distanceInCm, 150.0);
    });

    test('should convert to mm correctly', () {
      final record = MeasurementRecord(
        id: '1',
        distanceInMeters: 1.5,
        timestamp: DateTime.now(),
      );

      expect(record.distanceInMm, 1500.0);
    });

    test('should convert to inch correctly', () {
      final record = MeasurementRecord(
        id: '1',
        distanceInMeters: 1.0,
        timestamp: DateTime.now(),
      );

      expect(record.distanceInInch, closeTo(39.37, 0.01));
    });

    test('should format distance correctly', () {
      final record = MeasurementRecord(
        id: '1',
        distanceInMeters: 0.15,
        timestamp: DateTime.now(),
      );

      expect(record.formattedDistance, '15.00 cm');
    });

    test('should serialize to JSON', () {
      final record = MeasurementRecord(
        id: '1',
        distanceInMeters: 1.5,
        timestamp: DateTime(2026, 1, 8, 10, 30),
        label: '테스트',
      );

      final json = record.toJson();
      expect(json['id'], '1');
      expect(json['distanceInMeters'], 1.5);
      expect(json['label'], '테스트');
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': '1',
        'distanceInMeters': 1.5,
        'timestamp': '2026-01-08T10:30:00.000',
        'label': '테스트',
      };

      final record = MeasurementRecord.fromJson(json);
      expect(record.id, '1');
      expect(record.distanceInMeters, 1.5);
      expect(record.label, '테스트');
    });
  });
}
