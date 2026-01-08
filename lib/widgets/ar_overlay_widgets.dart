import 'package:flutter/material.dart';
import '../utils/measurement_utils.dart';

/// AR 화면 상단에 표시되는 상태 메시지 위젯
class StatusMessageOverlay extends StatelessWidget {
  final String message;

  const StatusMessageOverlay({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// 측정 결과를 표시하는 위젯
class MeasurementResultOverlay extends StatelessWidget {
  final double distanceInMeters;

  const MeasurementResultOverlay({
    super.key,
    required this.distanceInMeters,
  });

  @override
  Widget build(BuildContext context) {
    final cm = MeasurementUtils.metersToCm(distanceInMeters);
    final mm = MeasurementUtils.metersToMm(distanceInMeters);
    final inch = MeasurementUtils.metersToInch(distanceInMeters);

    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.amber[100],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${cm.toStringAsFixed(2)} cm',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${mm.toStringAsFixed(1)} mm  |  ${inch.toStringAsFixed(2)} inch',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 사용법 안내 위젯
class InstructionOverlay extends StatelessWidget {
  final String instruction;

  const InstructionOverlay({
    super.key,
    this.instruction = '평면 위의 두 점을 탭하여 거리를 측정하세요',
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          instruction,
          style: const TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// 화면 중앙 조준점 위젯
class CrosshairOverlay extends StatelessWidget {
  const CrosshairOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.add_circle_outline,
        color: Colors.white,
        size: 40,
      ),
    );
  }
}

/// AR 줄자 공통 AppBar
class ARRulerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onReset;

  const ARRulerAppBar({
    super.key,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('📏 AR 줄자'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onReset,
          tooltip: '초기화',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
