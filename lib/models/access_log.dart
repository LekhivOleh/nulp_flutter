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
}
