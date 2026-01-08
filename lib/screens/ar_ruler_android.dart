import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../constants/ar_constants.dart';
import '../utils/measurement_utils.dart';
import '../widgets/ar_overlay_widgets.dart';

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
  MeasurementState _measurementState = MeasurementState.searching;

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
      _measurementState = MeasurementState.scanning;
    });
  }

  void _onPlaneDetected(ArCorePlane plane) {
    setState(() {
      _measurementState = MeasurementState.planeDetected;
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
    _addSphere(
      position,
      _points.length == 1
          ? ARConstants.startPointColor
          : ARConstants.endPointColor,
    );

    if (_points.length == 2) {
      // 두 점이 찍혔으면 거리 계산
      final distance =
          MeasurementUtils.calculate3DDistance(_points[0], _points[1]);
      setState(() {
        _distance = distance;
        _measurementState = MeasurementState.measurementComplete;
      });

      // 선 그리기
      _drawLine();
    } else {
      setState(() {
        _measurementState = MeasurementState.firstPointSet;
      });
    }
  }

  void _addSphere(vm.Vector3 position, Color color) {
    final material = ArCoreMaterial(
      color: color,
      metallic: ARConstants.metallic,
    );

    final sphere = ArCoreSphere(
      radius: ARConstants.sphereRadius,
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
      color: ARConstants.lineColor,
      metallic: ARConstants.metallic,
    );

    // 두 점 사이의 거리와 방향 계산
    final start = _points[0];
    final end = _points[1];
    final distance = MeasurementUtils.calculate3DDistance(start, end);

    // 실린더로 선 표현
    final line = ArCoreCylinder(
      radius: ARConstants.lineRadius,
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
    final horizontalDistance =
        math.sqrt(direction.x * direction.x + direction.z * direction.z);
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
      _measurementState = MeasurementState.readyToMeasure;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ARRulerAppBar(onReset: _clearMeasurement),
      body: Stack(
        children: [
          // AR 뷰
          ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated,
            enableTapRecognizer: true,
            enablePlaneRenderer: true,
          ),
          // 상단 상태 메시지
          StatusMessageOverlay(message: _measurementState.message),
          // 하단 측정 결과
          if (_distance != null)
            MeasurementResultOverlay(distanceInMeters: _distance!),
          // 사용법 안내
          const InstructionOverlay(),
          // 조준점 (화면 중앙)
          const CrosshairOverlay(),
        ],
      ),
    );
  }
}
