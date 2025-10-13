import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/map_data.dart';
import '../utils/mqtt_service.dart';

// Enum to define the different transformation types for debugging.
enum TransformType { A, B, C, D }

class _LabelPoint {
  final String label;
  final Offset offset;
  _LabelPoint({required this.label, required this.offset});
}

class MapTrackingDialog extends StatefulWidget {
  final MapData mapInfo;
  final String robotUuid;
  final double resolution;

  const MapTrackingDialog({
    Key? key,
    required this.mapInfo,
    required this.robotUuid,
    required this.resolution,
  }) : super(key: key);

  @override
  _MapTrackingDialogState createState() => _MapTrackingDialogState();
}

class _MapTrackingDialogState extends State<MapTrackingDialog> {
  final MqttService _mqttService = MqttService();
  static const String mapBaseUrl = 'http://152.69.194.121:8000';

  ui.Image? _mapImage;
  String _status = 'Initializing...';
  bool _isDataReady = false;

  // --- Data for Display (One list for each transformation) ---
  final Map<TransformType, List<_LabelPoint>> _fixedPointsMap = {
    TransformType.A: [],
    TransformType.B: [],
    TransformType.C: [],
    TransformType.D: [],
  };

  // --- Temporarily disable MQTT for this view ---
  // Timer? _repaintTimer;
  // final List<Offset> _pointBuffer = [];
  // List<Offset> _trailPoints = [];

  @override
  void initState() {
    super.initState();
    _setupMapAndPoints();
  }

  @override
  void dispose() {
    // _repaintTimer?.cancel();
    // _mqttService.disconnect(widget.robotUuid);
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
    setState(() => _status = 'Loading map and calculating transformations...');

    final targetMapInfo = widget.mapInfo;

    if (targetMapInfo.mapOrigin.length < 2) {
      setState(() => _status = 'Error: Invalid map origin data.');
      return;
    }

    try {
      final fullMapUrl = '$mapBaseUrl${targetMapInfo.mapImage}';
      _mapImage = await _loadImage(fullMapUrl);

      // Generate points for each of the four transformation types
      for (var type in TransformType.values) {
        final pointsToDisplay = <_LabelPoint>[];
        targetMapInfo.coordinates.forEach((label, coords) {
          if (coords.length >= 2) {
            pointsToDisplay.add(_transformPoint(coords[0], coords[1], label, _mapImage!, targetMapInfo.mapOrigin, type));
          }
        });
        _fixedPointsMap[type] = pointsToDisplay;
      }

      setState(() {
        _status = 'Please identify the correct transformation (A, B, C, or D).';
        _isDataReady = true;
      });
    } catch (e) {
      setState(() => _status = 'Error loading map image: $e');
    }
  }

  _LabelPoint _transformPoint(double wx, double wy, String label, ui.Image image, List<double> mapOrigin, TransformType type) {
    double pixelX, pixelY;
    final ox = mapOrigin[0];
    final oy = mapOrigin[1];
    final res = widget.resolution;

    // All transformations are now variations of the original "Map B"
    switch (type) {
      case TransformType.A:
        // Original "Map B" formula
        pixelX = (ox - wy) / res;
        pixelY = (oy - wx) / res;
        break;
      case TransformType.B:
        // Flipped X-axis
        pixelX = (ox - wy) / -res;
        pixelY = (oy - wx) / res;
        break;
      case TransformType.C:
        // Flipped Y-axis
        pixelX = (ox - wy) / res;
        pixelY = (oy - wx) / -res;
        break;
      case TransformType.D:
        // Flipped both X and Y axes
        pixelX = (ox - wy) / -res;
        pixelY = (oy - wx) / -res;
        break;
    }
    return _LabelPoint(label: label, offset: Offset(pixelX, pixelY));
  }

  // --- MQTT connection temporarily disabled ---
  // void _connectMqtt() { ... }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (!_isDataReady || _mapImage == null) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_status),
          ],
        ),
      );
    } else {
      content = GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        padding: const EdgeInsets.all(4.0),
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
        children: TransformType.values.map((type) {
          return Card(
            elevation: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Map ${type.name}', style: Theme.of(context).textTheme.headlineSmall),
                ),
                Expanded(
                  child: InteractiveViewer(
                    maxScale: 5.0,
                    child: CustomPaint(
                      size: Size(_mapImage!.width.toDouble(), _mapImage!.height.toDouble()),
                      painter: MapAndRobotPainter(
                        mapImage: _mapImage!,
                        fixedPoints: _fixedPointsMap[type]!,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      title: const Text('Transformation Debug View (Round 2)'),
      contentPadding: const EdgeInsets.all(8),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Text(_status, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Expanded(child: content),
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
  final List<_LabelPoint> fixedPoints;

  MapAndRobotPainter({
    required this.mapImage,
    required this.fixedPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final mapSourceRect = Rect.fromLTWH(0, 0, mapImage.width.toDouble(), mapImage.height.toDouble());
    final canvasDestRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(mapImage, mapSourceRect, canvasDestRect, paint);

    for (final point in fixedPoints) {
      final scaledPosition = point.offset;
      final paintDot = Paint()..color = Colors.green; // Using green as per user's screenshot
      canvas.drawCircle(scaledPosition, 5, paintDot);
      final textPainter = TextPainter(
        text: TextSpan(text: point.label, style: const TextStyle(fontSize: 10, color: Colors.green, backgroundColor: Color(0x99FFFFFF))),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, scaledPosition + const Offset(8, -18));
    }
  }

  @override
  bool shouldRepaint(covariant MapAndRobotPainter oldDelegate) {
    return oldDelegate.mapImage != mapImage || oldDelegate.fixedPoints != fixedPoints;
  }
}
