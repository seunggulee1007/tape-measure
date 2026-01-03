import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../utils/measurement_utils.dart';

class ARRulerIOS extends StatefulWidget {
  const ARRulerIOS({super.key});

  @override
  State<ARRulerIOS> createState() => _ARRulerIOSState();
}

class _ARRulerIOSState extends State<ARRulerIOS> {
  late ARKitController _arkitController;

  // 측정 포인트들
  final List<vm.Vector3> _points = [];
  final List<ARKitNode> _sphereNodes = [];
  ARKitNode? _lineNode;
  ARKitNode? _textNode;

  // 측정 결과
  double? _distance;

  // 상태
  String _statusMessage = '평면을 찾는 중...';

  @override
  void dispose() {
    _arkitController.dispose();
    super.dispose();
  }

  void _onARKitViewCreated(ARKitController controller) {
    _arkitController = controller;

    // 평면 감지 활성화
    _arkitController.onAddNodeForAnchor = _onAnchorAdd;
    _arkitController.onUpdateNodeForAnchor = _onAnchorUpdate;

    // 탭 핸들러 설정
    _arkitController.onARTap = _onTap;

    setState(() {
      _statusMessage = '평면을 찾는 중... 핸드폰을 천천히 움직이세요';
    });
  }

  void _onAnchorAdd(ARKitAnchor anchor) {
    if (anchor is ARKitPlaneAnchor) {
      setState(() {
        _statusMessage = '평면 감지됨! 측정할 첫 번째 점을 탭하세요';
      });
    }
  }

  void _onAnchorUpdate(ARKitAnchor anchor) {
    // 평면 업데이트 처리
  }

  void _onTap(List<ARKitTestResult> results) {
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('표면을 탭해주세요')),
      );
      return;
    }

    final result = results.first;
    final position = vm.Vector3(
      result.worldTransform.getColumn(3).x,
      result.worldTransform.getColumn(3).y,
      result.worldTransform.getColumn(3).z,
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
      // 거리 텍스트 표시
      _addDistanceText();
    } else {
      setState(() {
        _statusMessage = '두 번째 점을 탭하세요';
      });
    }
  }

  void _addSphere(vm.Vector3 position, Color color) {
    final material = ARKitMaterial(
      diffuse: ARKitMaterialProperty.color(color),
    );

    final sphere = ARKitSphere(
      radius: 0.01, // 1cm 크기의 구
      materials: [material],
    );

    final node = ARKitNode(
      geometry: sphere,
      position: position,
    );

    _arkitController.add(node);
    _sphereNodes.add(node);
  }

  void _drawLine() {
    if (_points.length < 2) return;

    final material = ARKitMaterial(
      diffuse: ARKitMaterialProperty.color(Colors.red),
    );

    // 두 점 사이의 거리와 방향 계산
    final start = _points[0];
    final end = _points[1];
    final distance = MeasurementUtils.calculate3DDistance(start, end);

    // 실린더로 선 표현
    final line = ARKitCylinder(
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

    _lineNode = ARKitNode(
      geometry: line,
      position: midPoint,
      eulerAngles: _calculateEulerAngles(start, end),
    );

    _arkitController.add(_lineNode!);
  }

  vm.Vector3 _calculateEulerAngles(vm.Vector3 start, vm.Vector3 end) {
    final direction = end - start;

    // XZ 평면에서의 각도 (Y축 회전)
    final yaw = vm.degrees(math.atan2(direction.x, direction.z));

    // Y축 방향 각도 (X축 회전)
    final horizontalDistance = math.sqrt(direction.x * direction.x + direction.z * direction.z);
    final pitch = vm.degrees(math.atan2(direction.y, horizontalDistance));

    return vm.Vector3(
      vm.radians(pitch + 90), // 실린더는 기본적으로 Y축 방향이므로 90도 보정
      vm.radians(yaw),
      0,
    );
  }

  void _addDistanceText() {
    if (_distance == null || _points.length < 2) return;

    final midPoint = vm.Vector3(
      (_points[0].x + _points[1].x) / 2,
      (_points[0].y + _points[1].y) / 2 + 0.05, // 선 위에 표시
      (_points[0].z + _points[1].z) / 2,
    );

    final text = ARKitText(
      text: MeasurementUtils.formatDistance(_distance!),
      extrusionDepth: 0.002,
      materials: [
        ARKitMaterial(
          diffuse: ARKitMaterialProperty.color(Colors.white),
        ),
      ],
    );

    _textNode = ARKitNode(
      geometry: text,
      position: midPoint,
      scale: vm.Vector3(0.005, 0.005, 0.005),
    );

    _arkitController.add(_textNode!);
  }

  void _clearMeasurement() {
    // 구 노드 제거
    for (final node in _sphereNodes) {
      _arkitController.remove(node.name);
    }
    _sphereNodes.clear();

    // 선 노드 제거
    if (_lineNode != null) {
      _arkitController.remove(_lineNode!.name);
      _lineNode = null;
    }

    // 텍스트 노드 제거
    if (_textNode != null) {
      _arkitController.remove(_textNode!.name);
      _textNode = null;
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
          ARKitSceneView(
            onARKitViewCreated: _onARKitViewCreated,
            enableTapRecognizer: true,
            planeDetection: ARPlaneDetection.horizontal,
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
