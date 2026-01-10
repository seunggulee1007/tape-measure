import 'package:flutter_test/flutter_test.dart';
import 'package:tape_measure/services/ar_availability_service.dart';

void main() {
  group('ARAvailabilityService', () {
    test('should have checkARAvailability method', () {
      expect(ARAvailabilityService.checkARAvailability, isA<Function>());
    });

    test('should have isARSupported method', () {
      expect(ARAvailabilityService.isARSupported, isA<Function>());
    });

    test('should have getUnsupportedReason method', () {
      expect(ARAvailabilityService.getUnsupportedReason, isA<Function>());
    });
  });

  group('ARAvailabilityStatus', () {
    test('should have all expected statuses', () {
      expect(ARAvailabilityStatus.values.length, 4);
    });

    test('should have supported status', () {
      expect(ARAvailabilityStatus.supported.isSupported, true);
    });

    test('should have unsupported statuses', () {
      expect(ARAvailabilityStatus.unsupportedDevice.isSupported, false);
      expect(ARAvailabilityStatus.unsupportedPlatform.isSupported, false);
      expect(ARAvailabilityStatus.arCoreNotInstalled.isSupported, false);
    });

    test('should have correct messages', () {
      expect(ARAvailabilityStatus.supported.message, 'AR 사용 가능');
      expect(ARAvailabilityStatus.unsupportedDevice.message, contains('지원하지 않습니다'));
      expect(ARAvailabilityStatus.unsupportedPlatform.message, contains('iOS와 Android'));
      expect(ARAvailabilityStatus.arCoreNotInstalled.message, contains('ARCore'));
    });
  });
}
