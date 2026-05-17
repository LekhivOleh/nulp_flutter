import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

typedef UserInfo = ({String userId, String name});

class MqttUserLookupService {
  MqttUserLookupService({
    this.host = 'broker.hivemq.com',
    this.port = 1883,
  });

  final String host;
  final int port;

  static const String _queryTopic = 'nulp/users/query';
  static const Duration _timeout = Duration(seconds: 5);

  MqttServerClient? _client;

  Future<void> connect() async {
    final clientId = 'flutter_lookup_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient.withPort(host, clientId, port);
    _client!.keepAlivePeriod = 30;
    _client!.logging(on: false);

    try {
      await _client!.connect();
    } catch (_) {
      _client = null;
    }
  }

  void disconnect() {
    _client?.disconnect();
    _client = null;
  }

  Future<UserInfo?> lookupUser(String cardId) async {
    final state = _client?.connectionStatus?.state;
    if (_client == null || state != MqttConnectionState.connected) {
      await connect();
    }

    final client = _client;
    if (client == null) return null;

    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final replyTo = 'nulp/users/response/$requestId';

    client.subscribe(replyTo, MqttQos.atLeastOnce);

    final completer = Completer<UserInfo?>();

    final sub = client.updates?.listen((messages) {
      for (final msg in messages) {
        if (msg.topic == replyTo) {
          final payload = MqttPublishPayload.bytesToStringAsString(
            (msg.payload as MqttPublishMessage).payload.message,
          );
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            if (data['requestId'] == requestId) {
              completer.complete((
                userId: data['userId'] as String? ?? '',
                name: data['name'] as String? ?? 'Unknown',
              ));
            }
          } catch (_) {
            completer.complete(null);
          }
        }
      }
    });

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode({
      'cardId': cardId,
      'requestId': requestId,
      'replyTo': replyTo,
    }));

    client.publishMessage(_queryTopic, MqttQos.atLeastOnce, builder.payload!);

    try {
      return await completer.future.timeout(_timeout);
    } catch (_) {
      return null;
    } finally {
      await sub?.cancel();
      client.unsubscribe(replyTo);
    }
  }
}
