import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:uuid/uuid.dart';
import '../constants/ar_constants.dart';
import '../models/measurement_record.dart';
import '../services/haptic_service.dart';
import '../services/measurement_history_service.dart';
import '../services/share_service.dart';
import '../utils/measurement_utils.dart';
import '../widgets/ar_overlay_widgets.dart';

class ARRulerAndroid extends StatefulWidget {
  const ARRulerAndroid({super.key});

  @override
  State<ARRulerAndroid> createState() => _ARRulerAndroidState();
}

class _ARRulerAndroidState extends State<ARRulerAndroid> {
  ArCoreController? _arCoreController;
  final MeasurementHistoryService _historyService = MeasurementHistoryService();
  final Uuid _uuid = const Uuid();

  // 측정 포인트들
  final List<vm.Vector3> _points = [];
  final List<ArCoreNode> _sphereNodes = [];
  ArCoreNode? _lineNode;

  // 측정 결과
  double? _distance;

  // 상태
  MeasurementState _measurementState = MeasurementState.searching;
  PlaneDetectionMode _planeDetectionMode = PlaneDetectionMode.both;

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

  void _onPlaneTap(List<ArCoreHitTestResult> hits) async {
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

  void _undoLastPoint() {
    if (_points.isEmpty) return;

    // 마지막 점 제거
    _points.removeLast();

    // 마지막 구 노드 제거
    if (_sphereNodes.isNotEmpty) {
      final lastNode = _sphereNodes.removeLast();
      _arCoreController!.removeNode(nodeName: lastNode.name);
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
