class AccessLog {
  const AccessLog({
    required this.uid,
    required this.name,
    required this.direction,
    required this.timestamp,
  });

  final String uid;
  final String name;
  final String direction;
  final DateTime timestamp;

  AccessLog copyWith({
    String? uid,
    String? name,
    String? direction,
    DateTime? timestamp,
  }) {
    return AccessLog(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      direction: direction ?? this.direction,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'direction': direction,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AccessLog.fromJson(Map<String, dynamic> json) {
    return AccessLog(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      direction: json['direction'] as String? ?? 'In',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
