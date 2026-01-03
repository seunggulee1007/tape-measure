import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../utils/measurement_utils.dart';

class ARRulerAndroid extends StatefulWidget {
  const ARRulerAndroid({super.key});

  @override
  State<ARRulerAndroid> createState() => _ARRulerAndroidState();
}

class _ARRulerAndroidState extends State<ARRulerAndroid> {
  ArCoreController? _arCoreController;

  // 측정 포인트들
  final List<vm.Vector3> _points = [];
  final List<ArCoreNode> _sphereNodes = [];
  ArCoreNode? _lineNode;

  // 측정 결과
  double? _distance;

  // 상태
  String _statusMessage = '평면을 찾는 중...';

  @override
  void dispose() {
    _arCoreController?.dispose();
    super.dispose();
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    _arCoreController = controller;

    // 평면 감지 콜백
    _arCoreController!.onPlaneTap = _onPlaneTap;
    _arCoreController!.onPlaneDetected = _onPlaneDetected;

    setState(() {
      _statusMessage = '평면을 찾는 중... 핸드폰을 천천히 움직이세요';
    });
  }

  void _onPlaneDetected(ArCorePlane plane) {
    setState(() {
      _statusMessage = '평면 감지됨! 측정할 첫 번째 점을 탭하세요';
    });
  }

  void _onPlaneTap(List<ArCoreHitTestResult> hits) {
    if (hits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('표면을 탭해주세요')),
      );
      return;
    }

    final hit = hits.first;
    final position = vm.Vector3(
      hit.pose.translation.x,
      hit.pose.translation.y,
      hit.pose.translation.z,
    );

    if (_points.length >= 2) {
      // 리셋하고 새로 시작
      _clearMeasurement();
    }

    _points.add(position);
    _addSphere(position, _points.length == 1 ? Colors.green : Colors.red);

    if (_points.length == 2) {
      // 두 점이 찍혔으면 거리 계산
      final distance = MeasurementUtils.calculate3DDistance(_points[0], _points[1]);
      setState(() {
        _distance = distance;
        _statusMessage = '측정 완료! 다시 탭하면 새로 측정';
      });

      // 선 그리기
      _drawLine();
    } else {
      setState(() {
        _statusMessage = '두 번째 점을 탭하세요';
      });
    }
  }

  void _addSphere(vm.Vector3 position, Color color) {
    final material = ArCoreMaterial(
      color: color,
      metallic: 0.5,
    );

    final sphere = ArCoreSphere(
      radius: 0.01, // 1cm 크기의 구
      materials: [material],
    );

    final node = ArCoreNode(
      shape: sphere,
      position: position,
    );

    _arCoreController!.addArCoreNode(node);
    _sphereNodes.add(node);
  }

  void _drawLine() {
    if (_points.length < 2) return;

    final material = ArCoreMaterial(
      color: Colors.red,
      metallic: 0.5,
    );

    // 두 점 사이의 거리와 방향 계산
    final start = _points[0];
    final end = _points[1];
    final distance = MeasurementUtils.calculate3DDistance(start, end);

    // 실린더로 선 표현
    final line = ArCoreCylinder(
      radius: 0.002, // 2mm 두께
      height: distance,
      materials: [material],
    );

    // 중점 위치
    final midPoint = vm.Vector3(
      (start.x + end.x) / 2,
      (start.y + end.y) / 2,
      (start.z + end.z) / 2,
    );

    _lineNode = ArCoreNode(
      shape: line,
      position: midPoint,
      rotation: _calculateRotation(start, end),
    );

    _arCoreController!.addArCoreNode(_lineNode!);
  }

  vm.Vector4 _calculateRotation(vm.Vector3 start, vm.Vector3 end) {
    final direction = end - start;

    // XZ 평면에서의 각도
    final yaw = math.atan2(direction.x, direction.z);

    // Y축 방향 각도
    final horizontalDistance = math.sqrt(direction.x * direction.x + direction.z * direction.z);
    final pitch = math.atan2(direction.y, horizontalDistance);

    // Euler 각도를 Quaternion으로 변환
    final q = vm.Quaternion.euler(pitch + math.pi / 2, yaw, 0);

    return vm.Vector4(q.x, q.y, q.z, q.w);
  }

  void _clearMeasurement() {
    // 구 노드 제거
    for (final node in _sphereNodes) {
      _arCoreController!.removeNode(nodeName: node.name);
    }
    _sphereNodes.clear();

    // 선 노드 제거
    if (_lineNode != null) {
      _arCoreController!.removeNode(nodeName: _lineNode!.name);
      _lineNode = null;
    }

    _points.clear();
    setState(() {
      _distance = null;
      _statusMessage = '첫 번째 점을 탭하세요';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📏 AR 줄자'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearMeasurement,
            tooltip: '초기화',
          ),
        ],
      ),
      body: Stack(
        children: [
          // AR 뷰
          ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated,
            enableTapRecognizer: true,
            enablePlaneRenderer: true,
          ),
          // 상단 상태 메시지
          Positioned(
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
                _statusMessage,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // 하단 측정 결과
          if (_distance != null)
            Positioned(
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
                      '${MeasurementUtils.metersToCm(_distance!).toStringAsFixed(2)} cm',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${MeasurementUtils.metersToMm(_distance!).toStringAsFixed(1)} mm  |  '
                      '${MeasurementUtils.metersToInch(_distance!).toStringAsFixed(2)} inch',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // 사용법 안내
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '평면 위의 두 점을 탭하여 거리를 측정하세요',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // 조준점 (화면 중앙)
          const Center(
            child: Icon(
              Icons.add_circle_outline,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}
