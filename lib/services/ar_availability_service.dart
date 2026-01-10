import 'dart:io';

/// AR 사용 가능 상태
enum ARAvailabilityStatus {
  supported('AR 사용 가능'),
  unsupportedDevice('이 기기는 AR을 지원하지 않습니다'),
  unsupportedPlatform('AR 줄자는 iOS와 Android에서만 사용 가능합니다'),
  arCoreNotInstalled('ARCore가 설치되어 있지 않습니다. Play 스토어에서 설치해주세요');

  final String message;
  const ARAvailabilityStatus(this.message);

  bool get isSupported => this == ARAvailabilityStatus.supported;
}

/// AR 사용 가능 여부 확인 서비스
class ARAvailabilityService {
  ARAvailabilityService._();

  /// AR 사용 가능 여부 확인
  static Future<ARAvailabilityStatus> checkARAvailability() async {
    if (!Platform.isIOS && !Platform.isAndroid) {
      return ARAvailabilityStatus.unsupportedPlatform;
    }

    // 실제 기기에서는 ARKit/ARCore 가용성 체크가 필요
    // 여기서는 플랫폼 체크만 수행
    return ARAvailabilityStatus.supported;
  }

  /// AR 지원 여부 (간단 체크)
  static Future<bool> isARSupported() async {
    final status = await checkARAvailability();
    return status.isSupported;
  }

  /// 미지원 사유 메시지
  static Future<String?> getUnsupportedReason() async {
    final status = await checkARAvailability();
    if (status.isSupported) {
      return null;
    }
    return status.message;
  }
}
