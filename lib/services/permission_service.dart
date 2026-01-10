import 'package:permission_handler/permission_handler.dart';

/// 권한 관리 서비스
class PermissionService {
  PermissionService._();

  /// 카메라 권한 요청
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// 카메라 권한 상태 확인
  static Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  /// 권한이 영구 거부되었는지 확인
  static Future<bool> isCameraPermissionPermanentlyDenied() async {
    return await Permission.camera.isPermanentlyDenied;
  }

  /// 앱 설정 열기
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
