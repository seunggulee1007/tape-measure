import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../constants/ar_constants.dart';
import '../utils/measurement_utils.dart';
import '../widgets/ar_overlay_widgets.dart';

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
  MeasurementState _measurementState = MeasurementState.searching;

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
      _measurementState = MeasurementState.scanning;
    });
  }

  void _onAnchorAdd(ARKitAnchor anchor) {
    if (anchor is ARKitPlaneAnchor) {
      setState(() {
        _measurementState = MeasurementState.planeDetected;
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
      // 거리 텍스트 표시
      _addDistanceText();
    } else {
      setState(() {
        _measurementState = MeasurementState.firstPointSet;
      });
    }
  }

  void _addSphere(vm.Vector3 position, Color color) {
    final material = ARKitMaterial(
      diffuse: ARKitMaterialProperty.color(color),
    );

    final sphere = ARKitSphere(
      radius: ARConstants.sphereRadius,
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
      diffuse: ARKitMaterialProperty.color(ARConstants.lineColor),
    );

    // 두 점 사이의 거리와 방향 계산
    final start = _points[0];
    final end = _points[1];
    final distance = MeasurementUtils.calculate3DDistance(start, end);

    // 실린더로 선 표현
    final line = ARKitCylinder(
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
    final horizontalDistance =
        math.sqrt(direction.x * direction.x + direction.z * direction.z);
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
      (_points[0].y + _points[1].y) / 2 + ARConstants.textOffsetY,
      (_points[0].z + _points[1].z) / 2,
    );

    final text = ARKitText(
      text: MeasurementUtils.formatDistance(_distance!),
      extrusionDepth: ARConstants.textExtrusionDepth,
      materials: [
        ARKitMaterial(
          diffuse: ARKitMaterialProperty.color(ARConstants.textColor),
        ),
      ],
    );

    _textNode = ARKitNode(
      geometry: text,
      position: midPoint,
      scale: vm.Vector3(
        ARConstants.textScale,
        ARConstants.textScale,
        ARConstants.textScale,
      ),
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
          ARKitSceneView(
            onARKitViewCreated: _onARKitViewCreated,
            enableTapRecognizer: true,
            planeDetection: ARPlaneDetection.horizontal,
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
