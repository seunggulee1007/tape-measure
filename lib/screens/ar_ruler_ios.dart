import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:uuid/uuid.dart';
import '../constants/ar_constants.dart';
import '../models/measurement_record.dart';
import '../services/haptic_service.dart';
import '../services/measurement_history_service.dart';
import '../services/share_service.dart';
import '../utils/measurement_utils.dart';
import '../widgets/ar_overlay_widgets.dart';

class ARRulerIOS extends StatefulWidget {
  const ARRulerIOS({super.key});

  @override
  State<ARRulerIOS> createState() => _ARRulerIOSState();
}

class _ARRulerIOSState extends State<ARRulerIOS> {
  late ARKitController _arkitController;
  final MeasurementHistoryService _historyService = MeasurementHistoryService();
  final Uuid _uuid = const Uuid();

  // 측정 포인트들
  final List<vm.Vector3> _points = [];
  final List<ARKitNode> _sphereNodes = [];
  ARKitNode? _lineNode;
  ARKitNode? _textNode;

  // 측정 결과
  double? _distance;

  // 상태
  MeasurementState _measurementState = MeasurementState.searching;
  PlaneDetectionMode _planeDetectionMode = PlaneDetectionMode.both;

  @override
  void dispose() {
    _arkitController.dispose();
    super.dispose();
  }

  ARPlaneDetection _getARPlaneDetection() {
    switch (_planeDetectionMode) {
      case PlaneDetectionMode.horizontal:
        return ARPlaneDetection.horizontal;
      case PlaneDetectionMode.vertical:
        return ARPlaneDetection.vertical;
      case PlaneDetectionMode.both:
        return ARPlaneDetection.horizontalAndVertical;
    }
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

  void _onTap(List<ARKitTestResult> results) async {
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

    // 햅틱 피드백
    await HapticService.lightImpact();

    if (_points.length == 2) {
      // 두 점이 찍혔으면 거리 계산
      final distance =
          MeasurementUtils.calculate3DDistance(_points[0], _points[1]);
      setState(() {
        _distance = distance;
        _measurementState = MeasurementState.measurementComplete;
      });

      // 히스토리에 추가
      final record = MeasurementRecord(
        id: _uuid.v4(),
        distanceInMeters: distance,
        timestamp: DateTime.now(),
      );
      _historyService.addRecord(record);

      // 강한 햅틱 피드백
      await HapticService.mediumImpact();

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

  void _undoLastPoint() {
    if (_points.isEmpty) return;

    // 마지막 점 제거
    _points.removeLast();

    // 마지막 구 노드 제거
    if (_sphereNodes.isNotEmpty) {
      final lastNode = _sphereNodes.removeLast();
      _arkitController.remove(lastNode.name);
    }

    setState(() {
      _distance = null;
      _measurementState = _points.isEmpty
          ? MeasurementState.readyToMeasure
          : MeasurementState.firstPointSet;
    });

    HapticService.lightImpact();
  }

  void _shareLastMeasurement() {
    final records = _historyService.records;
    if (records.isNotEmpty) {
      ShareService.shareRecord(records.first);
    }
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildHistorySheet(),
    );
  }

  Widget _buildHistorySheet() {
    final records = _historyService.records;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '측정 기록',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (records.isNotEmpty)
                TextButton(
                  onPressed: () {
                    _historyService.clearAll();
                    Navigator.pop(context);
                  },
                  child: const Text('전체 삭제'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (records.isEmpty)
            const Center(child: Text('측정 기록이 없습니다'))
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return ListTile(
                    leading: const Icon(Icons.straighten),
                    title: Text(record.formattedDistance),
                    subtitle: Text(
                      '${record.timestamp.month}/${record.timestamp.day} '
                      '${record.timestamp.hour}:${record.timestamp.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => ShareService.shareRecord(record),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showPlaneDetectionOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '평면 감지 모드',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...PlaneDetectionMode.values.map((mode) => RadioListTile<PlaneDetectionMode>(
                  title: Text(mode.label),
                  value: mode,
                  groupValue: _planeDetectionMode,
                  onChanged: (value) {
                    setState(() {
                      _planeDetectionMode = value!;
                    });
                    Navigator.pop(context);
                    // AR 세션 재시작 필요 안내
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('앱을 재시작하면 새 모드가 적용됩니다')),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📏 AR 줄자'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _points.isNotEmpty ? _undoLastPoint : null,
            tooltip: '실행 취소',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistorySheet,
            tooltip: '측정 기록',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareLastMeasurement();
                  break;
                case 'plane':
                  _showPlaneDetectionOptions();
                  break;
                case 'reset':
                  _clearMeasurement();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('공유'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'plane',
                child: Row(
                  children: [
                    Icon(Icons.layers),
                    SizedBox(width: 8),
                    Text('평면 감지 모드'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('초기화'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // AR 뷰
          ARKitSceneView(
            onARKitViewCreated: _onARKitViewCreated,
            enableTapRecognizer: true,
            planeDetection: _getARPlaneDetection(),
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
