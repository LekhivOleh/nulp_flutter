import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:my_project/services/log_service.dart';
import 'package:my_project/services/mqtt_payload_parser.dart';

class MqttAccessLogSyncService {
  MqttAccessLogSyncService(
    this._logService, {
    this.host = 'broker.hivemq.com',
    this.port = 1883,
    this.topic = 'nulp/access/events',
    String clientIdPrefix = 'flutter_access_sync_client',
  }) : _clientIdPrefix = clientIdPrefix;

  final LogService _logService;
  final String host;
  final int port;
  final String topic;
  final String _clientIdPrefix;

  MqttServerClient? _client;
  StreamSubscription<
      List<MqttReceivedMessage<MqttMessage>>>? _updatesSubscription;
  Timer? _reconnectTimer;
  bool _started = false;
  String _lastEventFingerprint = '';

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> start() async {
    if (_started) {
      return;
    }

    _started = true;
    await _connect();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_started || isConnected) {
        return;
      }
      unawaited(_connect());
    });
  }

  Future<void> dispose() async {
    _started = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _updatesSubscription?.cancel();
    _updatesSubscription = null;

    _client?.disconnect();
    _client = null;
  }

  Future<void> _connect() async {
    if (!_started || isConnected) {
      return;
    }

    final clientId =
        '$_clientIdPrefix-${DateTime.now().millisecondsSinceEpoch}';
    final client = MqttServerClient(host, clientId)
      ..port = port
      ..keepAlivePeriod = 20
      ..autoReconnect = true
      ..resubscribeOnAutoReconnect = true
      ..logging(on: false)
      ..onDisconnected = _onDisconnected;

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    try {
      await client.connect();
    } catch (_) {
      client.disconnect();
      return;
    }

    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      client.disconnect();
      return;
    }

    _client = client;
    client.subscribe(topic, MqttQos.atMostOnce);

    await _updatesSubscription?.cancel();
    _updatesSubscription = client.updates?.listen(_handleUpdates);
  }

  void _onDisconnected() {
    if (!_started) {
      return;
    }
    _client = null;
  }

  void _handleUpdates(List<MqttReceivedMessage<MqttMessage>> messages) {
    if (messages.isEmpty) {
      return;
    }

    final payloadMessage = messages.first.payload;
    if (payloadMessage is! MqttPublishMessage) {
      return;
    }

    final payload = utf8.decode(payloadMessage.payload.message);
    unawaited(_persistAccessEvent(payload));
  }

  Future<void> _persistAccessEvent(String payload) async {
    final log = parseMqttAccessLog(payload);
    if (log == null) return;

    final ts = log.timestamp.toIso8601String();
    final fingerprint =
        '${log.uid}|${log.userId}|${log.name}|${log.direction}|$ts';

    if (fingerprint == _lastEventFingerprint) return;
    _lastEventFingerprint = fingerprint;

    await _logService.addLog(log: log, userId: log.userId);
  }
}
