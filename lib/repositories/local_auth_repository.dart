import 'dart:convert';

import 'package:my_project/data/local/key_value_storage.dart';
import 'package:my_project/models/app_user.dart';
import 'package:my_project/repositories/auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._storage);

  final KeyValueStorage _storage;

  static const String _userKey = 'registered_user';
  static const String _isLoggedInKey = 'is_logged_in';

  @override
  Future<void> register({required AppUser user}) async {
    final payload = jsonEncode(user.toJson());
    await _storage.writeString(key: _userKey, value: payload);
  }

  @override
  Future<bool> login({required String email, required String password}) async {
    final user = await getRegisteredUser();
    if (user == null) {
      return false;
    }

    final isMatch = user.email == email && user.password == password;
    await _storage.writeString(
      key: _isLoggedInKey,
      value: isMatch ? 'true' : 'false',
    );
    return isMatch;
  }

  @override
  Future<void> logout() async {
    await _storage.writeString(key: _isLoggedInKey, value: 'false');
  }

  @override
  Future<AppUser?> getRegisteredUser() async {
    final raw = await _storage.readString(key: _userKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AppUser.fromJson(decoded);
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final loggedIn = await isLoggedIn();
    if (!loggedIn) {
      return null;
    }
    return getRegisteredUser();
  }

  @override
  Future<void> updateCurrentUser({required AppUser user}) async {
    await register(user: user);
  }

  @override
  Future<void> deleteCurrentUser() async {
    await _storage.remove(key: _userKey);
    await _storage.writeString(key: _isLoggedInKey, value: 'false');
  }

  @override
  Future<bool> isLoggedIn() async {
    final value = await _storage.readString(key: _isLoggedInKey);
    return value == 'true';
  }
}
