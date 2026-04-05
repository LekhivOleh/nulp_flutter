abstract class KeyValueStorage {
  Future<void> writeString({required String key, required String value});

  Future<String?> readString({required String key});

  Future<void> remove({required String key});
}
