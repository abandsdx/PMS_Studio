import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// A simple data class to represent a 2D coordinate point.
class Point {
  final int x;
  final int y;
  Point(this.x, this.y);
}

/// A service class to manage MQTT communication.
///
/// In this standalone version, it has been modified to include a mock data
/// generator for demonstration purposes when a real MQTT broker is not available.
class MqttService {
  // --- Singleton Pattern ---
  static final MqttService _instance = MqttService._internal();
  factory MqttService() {
    return _instance;
  }
  MqttService._internal();
  // --- End Singleton ---

  MqttServerClient? _client;
  final String _server = 'log.labqtech.com';
  final int _port = 1883;
  final String _username = 'qoo';
  final String _password = 'qoowater';

  final StreamController<Point> _positionStreamController = StreamController.broadcast();
  Stream<Point> get positionStream => _positionStreamController.stream;

  // --- Mock Data Generation ---
  Timer? _mockDataTimer;
  bool _useMockData = true; // Set to false to try connecting to the real MQTT broker

  /// Connects to the MQTT broker or starts the mock data generator.
  Future<void> connectAndListen(String robotUuid) async {
    if (_useMockData) {
      _startMockDataGenerator();
      return;
    }

    // If client is already connected, just subscribe to the new topic.
    if (_client != null && _client?.connectionStatus?.state == MqttConnectionState.connected) {
      _subscribeToTopic(robotUuid);
      return;
    }

    final clientId = 'standalone_map_client_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient.withPort(_server, clientId, _port);

    _client!.logging(on: kDebugMode);
    _client!.keepAlivePeriod = 60;
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = () => _onConnected(robotUuid);
    _client!.onSubscribed = _onSubscribed;

    final connMessage = MqttConnectMessage()
      .withClientIdentifier(clientId)
      .startClean()
      .authenticateAs(_username, _password);
    _client!.connectionMessage = connMessage;

    try {
      print('Connecting to MQTT broker...');
      await _client!.connect();
    } catch (e) {
      print('MQTT Exception: $e');
      disconnect(robotUuid);
    }
  }

  /// Starts a timer to periodically generate and stream mock robot positions.
  void _startMockDataGenerator() {
    print("Starting mock data generator...");
    int step = 0;
    const int stepsPerSide = 50;
    const int sideLength = 2000; // In millimeters, matching the original data format

    _mockDataTimer?.cancel(); // Cancel any existing timer
    _mockDataTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      int x = 0;
      int y = 0;
      int side = (step ~/ stepsPerSide) % 4;
      int stepOnSide = step % stepsPerSide;

      switch (side) {
        case 0: // Move right
          x = stepOnSide * (sideLength ~/ stepsPerSide);
          y = 0;
          break;
        case 1: // Move down
          x = sideLength;
          y = stepOnSide * (sideLength ~/ stepsPerSide);
          break;
        case 2: // Move left
          x = sideLength - (stepOnSide * (sideLength ~/ stepsPerSide));
          y = sideLength;
          break;
        case 3: // Move up
          x = 0;
          y = sideLength - (stepOnSide * (sideLength ~/ stepsPerSide));
          break;
      }

      // Start position offset to center the square
      x += 1000;
      y -= 4000;

      final point = Point(x, y);
      _positionStreamController.add(point);
      step++;
    });
  }


  void _onConnected(String robotUuid) {
    print('MQTT client connected.');
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
      try {
        final jsonData = jsonDecode(payload);
        if (jsonData['Position'] != null) {
          final position = jsonData['Position'];
          if (position['x'] is int && position['y'] is int) {
            final point = Point(position['x'], position['y']);
            _positionStreamController.add(point);
          }
        }
      } catch (e) {
        print('Error parsing MQTT message: $e');
      }
    });

    _subscribeToTopic(robotUuid);
  }

  void _subscribeToTopic(String robotUuid) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      final topic = '/$robotUuid/from_rvc/SLAMPosition';
      print('Subscribing to topic: $topic');
      _client!.subscribe(topic, MqttQos.atMostOnce);
    }
  }

  void _onDisconnected() {
    print('MQTT client disconnected.');
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  /// Unsubscribes from a topic or stops the mock data generator.
  void disconnect(String robotUuid) {
    if (_useMockData) {
       print("Stopping mock data generator...");
      _mockDataTimer?.cancel();
      return;
    }

    final topic = '/$robotUuid/from_rvc/SLAMPosition';
    print('Unsubscribing from topic: $topic');
    _client?.unsubscribe(topic);
  }

  /// Disposes the client and closes the stream.
  void dispose() {
    _mockDataTimer?.cancel();
    _client?.disconnect();
    _positionStreamController.close();
  }
}