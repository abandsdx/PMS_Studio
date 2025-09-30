import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/map_info.dart';
import '../utils/mqtt_service.dart';
import '../config/mock_config.dart';

/// A data class to hold the label and pixel offset of a fixed point on the map.
class _LabelPoint {
  final String label;
  final Offset offset;
  _LabelPoint({required this.label, required this.offset});
}

/// A stateful dialog that displays a map and tracks a robot's position in real-time.
class MapTrackingDialog extends StatefulWidget {
  final MapInfo mapInfo;
  final String robotUuid;

  const MapTrackingDialog({
    Key? key,
    required this.mapInfo,
    required this.robotUuid,
  }) : super(key: key);

  @override
  _MapTrackingDialogState createState() => _MapTrackingDialogState();
}

class _MapTrackingDialogState extends State<MapTrackingDialog> {
  // --- Services and Constants ---
  final MqttService _mqttService = MqttService();
  final double _resolution = 0.05; // meters per pixel

  // --- State Variables ---
  ui.Image? _mapImage;
  String _status = 'Initializing...';
  bool _isDataReady = false;

  // -- State for real-time drawing --
  Timer? _repaintTimer;
  final List<Offset> _pointBuffer = [];
  List<Offset> _trailPoints = [];

  // --- Data for Display ---
  List<_LabelPoint> _fixedPointsPx = [];

  // A hardcoded map of all possible named locations and their world coordinates.
  // In a real app, this might come from a config file or an API.
  final Map<String, List<double>> _allPossiblePoints = MockConfig.allPossiblePoints;

  @override
  void initState() {
    super.initState();
    _setupMapAndPoints();
  }

  @override
  void dispose() {
    _repaintTimer?.cancel();
    _mqttService.disconnect(widget.robotUuid);
    super.dispose();
  }

  Future<ui.Image> _loadImage(String imageUrl) {
    final completer = Completer<ui.Image>();
    NetworkImage(imageUrl).resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (info, _) => completer.complete(info.image),
        onError: (e, s) => completer.completeError(e),
      ),
    );
    return completer.future;
  }

  void _setupMapAndPoints() async {
    setState(() => _status = 'Loading map data...');

    final targetMapInfo = widget.mapInfo;

    if (targetMapInfo.mapOrigin.length >= 2) {
      String finalPath = targetMapInfo.mapImage.replaceAll(' ', '');
      if (finalPath.startsWith('outputs/')) {
        finalPath = finalPath.substring('outputs/'.length);
      }
      final fullMapUrl = '${MockConfig.mapBaseUrl}/$finalPath';

      ui.Image loadedImage;
      try {
        loadedImage = await _loadImage(fullMapUrl);
      } catch (e) {
        setState(() => _status = 'Error loading map image: $e');
        return;
      }

      final pointsToDisplay = <_LabelPoint>[];
      for (String rLocationName in targetMapInfo.rLocations) {
        if (_allPossiblePoints.containsKey(rLocationName)) {
          final coords = _allPossiblePoints[rLocationName]!;
          pointsToDisplay.add(_transformPoint(coords[0], coords[1], rLocationName, loadedImage, targetMapInfo.mapOrigin));
        }
      }

      setState(() {
        _mapImage = loadedImage;
        _fixedPointsPx = pointsToDisplay;
        _status = 'Map data loaded. Listening for robot position...';
        _isDataReady = true;
      });
      _connectMqtt();
    } else {
      setState(() => _status = 'Error: Invalid map origin data for ${targetMapInfo.mapName}');
    }
  }

  _LabelPoint _transformPoint(double wx, double wy, String label, ui.Image image, List<double> mapOrigin) {
    final mapX = (mapOrigin[0] - wy) / _resolution;
    final mapY = (mapOrigin[1] - wx) / _resolution;
    return _LabelPoint(label: label, offset: Offset(mapX, mapY));
  }

  void _connectMqtt() {
    _repaintTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_pointBuffer.isNotEmpty && mounted) {
        setState(() {
          _trailPoints = List.from(_trailPoints)..addAll(_pointBuffer);
          _pointBuffer.clear();
        });
      }
    });

    _mqttService.positionStream.listen((Point point) {
      if (!mounted || !_isDataReady) return;

      final robotX_m = point.x / 1000.0;
      final robotY_m = point.y / 1000.0;

      final mapOrigin = widget.mapInfo.mapOrigin;
      final pixelX = (mapOrigin[0] - robotY_m) / _resolution;
      final pixelY = (mapOrigin[1] - robotX_m) / _resolution;

      _pointBuffer.add(Offset(pixelX, pixelY));
    });
    _mqttService.connectAndListen(widget.robotUuid);
  }

  @override
  Widget build(BuildContext context) {
    Widget mapContent;
    if (_mapImage == null) {
      mapContent = Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(_status),
        ],
      ));
    } else {
      mapContent = InteractiveViewer(
        maxScale: 5.0,
        child: CustomPaint(
          size: Size(_mapImage!.width.toDouble(), _mapImage!.height.toDouble()),
          painter: MapAndRobotPainter(
            mapImage: _mapImage!,
            trailPoints: _trailPoints,
            fixedPoints: _fixedPointsPx,
          ),
        ),
      );
    }

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      title: const Text('Real-time Position Tracking'),
      contentPadding: const EdgeInsets.all(8),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          children: [
            Text(_status, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.blueGrey)),
                child: mapContent,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class MapAndRobotPainter extends CustomPainter {
  final ui.Image mapImage;
  final List<Offset> trailPoints;
  final List<_LabelPoint> fixedPoints;

  MapAndRobotPainter({
    required this.mapImage,
    required this.trailPoints,
    required this.fixedPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final mapSourceRect = Rect.fromLTWH(0, 0, mapImage.width.toDouble(), mapImage.height.toDouble());
    // Draw the map to fit the canvas size
    final canvasDestRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(mapImage, mapSourceRect, canvasDestRect, paint);

    // No scaling needed here because the CustomPaint size is the image size.
    // The InteractiveViewer handles the scaling for the user.

    for (final point in fixedPoints) {
      final scaledPosition = point.offset; // Already in image pixel coordinates
      final paintDot = Paint()..color = Colors.red;
      canvas.drawCircle(scaledPosition, 5, paintDot);
      final textPainter = TextPainter(
        text: TextSpan(text: point.label, style: const TextStyle(fontSize: 10, color: Colors.red, backgroundColor: Color(0x99FFFFFF))),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, scaledPosition + const Offset(8, -18));
    }

    if (trailPoints.isNotEmpty) {
      final path = Path();
      path.moveTo(trailPoints.first.dx, trailPoints.first.dy);
      for (int i = 1; i < trailPoints.length; i++) {
        path.lineTo(trailPoints[i].dx, trailPoints[i].dy);
      }
      final trailPaint = Paint()..color = Colors.blue.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 2.0;
      canvas.drawPath(path, trailPaint);

      final currentPosition = trailPoints.last;
      final paintDot = Paint()..style = PaintingStyle.fill..color = const Color(0xFF2E7D32);
      canvas.drawCircle(currentPosition, 6, paintDot);
      final paintHalo = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0x802E7D32);
      canvas.drawCircle(currentPosition, 10, paintHalo);
    }
  }

  @override
  bool shouldRepaint(covariant MapAndRobotPainter oldDelegate) {
    return oldDelegate.mapImage != mapImage ||
           oldDelegate.trailPoints.length != trailPoints.length ||
           oldDelegate.fixedPoints != fixedPoints;
  }
}