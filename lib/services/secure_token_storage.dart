import 'package:my_project/data/local/key_value_storage.dart';

class SecureTokenStorage {
  SecureTokenStorage(this._storage);

  final KeyValueStorage _storage;
  static const String _tokenKey = 'superduper_secure_token';

  Future<String?> getToken() async {
    return _storage.readString(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _storage.writeString(key: _tokenKey, value: token);
  }

  Future<void> deleteToken() async {
    await _storage.remove(key: _tokenKey);
  }
}
