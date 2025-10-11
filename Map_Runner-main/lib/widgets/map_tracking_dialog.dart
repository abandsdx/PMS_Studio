import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../utils/mqtt_service.dart';

/// A data class to hold the label and pixel offset of a fixed point on the map.
class _LabelPoint {
  final String label;
  final Offset offset;
  final List<double> coordinates;
  _LabelPoint({required this.label, required this.offset, required this.coordinates});
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
      final fullMapUrl = 'http://152.69.194.121:8000${targetMapInfo.mapImage}';

      ui.Image loadedImage;
      try {
        loadedImage = await _loadImage(fullMapUrl);
      } catch (e) {
        setState(() => _status = 'Error loading map image: $e');
        return;
      }

      final pointsToDisplay = <_LabelPoint>[];
      final mapOrigin = targetMapInfo.mapOrigin;

      targetMapInfo.coordinates.forEach((locationName, coords) {
        if (coords.length >= 2) {
          final worldX = coords[0];
          final worldY = coords[1];

          // Corrected transformation logic
          final pixelX = (worldX - mapOrigin[0]) / _resolution;
          final pixelY = (worldY - mapOrigin[1]) / -_resolution; // Y is inverted

          pointsToDisplay.add(_LabelPoint(
            label: locationName,
            offset: Offset(pixelX, pixelY),
            coordinates: coords,
          ));
        }
      });

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
      // Corrected transformation logic for the robot's trail
      final pixelX = (robotX_m - mapOrigin[0]) / _resolution;
      final pixelY = (robotY_m - mapOrigin[1]) / -_resolution;

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
    final canvasDestRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(mapImage, mapSourceRect, canvasDestRect, paint);

    for (final point in fixedPoints) {
      final position = point.offset;
      final paintDot = Paint()..color = Colors.red;
      canvas.drawCircle(position, 5, paintDot);

      final coordText = '[${point.coordinates[0].toStringAsFixed(2)}, ${point.coordinates[1].toStringAsFixed(2)}]';
      final fullLabel = '${point.label} $coordText';

      final textPainter = TextPainter(
        text: TextSpan(
          text: fullLabel,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.red,
            backgroundColor: Color(0x99FFFFFF),
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, position + const Offset(8, -18));
    }

    if (trailPoints.isNotEmpty) {
      final path = Path();
      path.moveTo(trailPoints.first.dx, trailPoints.first.dy);
      for (int i = 1; i < trailPoints.length; i++) {
        path.lineTo(trailPoints[i].dx, trailPoints[i].dy);
      }
      final trailPaint = Paint()
        ..color = const Color(0xCC2196F3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
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