import 'dart:convert';

import 'package:my_project/models/access_log.dart';

AccessLog? parseMqttAccessLog(String payload) {
  Map<String, dynamic> decoded;
  try {
    decoded = jsonDecode(payload) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }

  final uid = _str(decoded['uid']);
  final userId = _str(decoded['userId']);
  final name = _str(decoded['name']);
  final direction = _str(decoded['direction']);
  final timestampRaw = _str(decoded['timestamp']);

  if (uid.isEmpty || userId.isEmpty || name.isEmpty || direction.isEmpty) {
    return null;
  }

  final timestamp =
      DateTime.tryParse(timestampRaw)?.toUtc() ?? DateTime.now().toUtc();

  return AccessLog(
    uid: uid,
    userId: userId,
    name: name,
    direction: direction,
    timestamp: timestamp,
  );
}

String _str(dynamic value) => value is String ? value.trim() : '';
