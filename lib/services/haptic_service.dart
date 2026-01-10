import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// 햅틱 피드백 서비스
class HapticService {
  HapticService._();

  /// 가벼운 햅틱 피드백
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// 중간 햅틱 피드백
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// 강한 햅틱 피드백
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// 커스텀 진동 (duration: 밀리초)
  static Future<void> vibrate({int duration = 100}) async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      await Vibration.vibrate(duration: duration);
    }
  }
}
