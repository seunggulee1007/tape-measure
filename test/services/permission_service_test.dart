import 'package:flutter_test/flutter_test.dart';
import 'package:tape_measure/services/permission_service.dart';

void main() {
  group('PermissionService', () {
    test('should have requestCameraPermission method', () {
      expect(PermissionService.requestCameraPermission, isA<Function>());
    });

    test('should have hasCameraPermission method', () {
      expect(PermissionService.hasCameraPermission, isA<Function>());
    });

    test('should have isCameraPermissionPermanentlyDenied method', () {
      expect(PermissionService.isCameraPermissionPermanentlyDenied, isA<Function>());
    });

    test('should have openSettings method', () {
      expect(PermissionService.openSettings, isA<Function>());
    });
  });
}
