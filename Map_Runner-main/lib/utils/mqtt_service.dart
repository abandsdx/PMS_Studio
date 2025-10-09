import 'dart:async';
import 'dart:convert';
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

  /// Connects to the MQTT broker.
  Future<void> connectAndListen(String robotUuid) async {
    // If client is already connected, just subscribe to the new topic.
    if (_client != null && _client?.connectionStatus?.state == MqttConnectionState.connected) {
      _subscribeToTopic(robotUuid);
      return;
    }

    final clientId = 'map_runner_client_${DateTime.now().millisecondsSinceEpoch}';
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

  /// Unsubscribes from a topic.
  void disconnect(String robotUuid) {
    final topic = '/$robotUuid/from_rvc/SLAMPosition';
    print('Unsubscribing from topic: $topic');
    _client?.unsubscribe(topic);
  }

  /// Disposes the client and closes the stream.
  void dispose() {
    _client?.disconnect();
    _positionStreamController.close();
  }
}