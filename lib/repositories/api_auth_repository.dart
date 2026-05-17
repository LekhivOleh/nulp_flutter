import 'dart:convert';

import 'package:my_project/data/local/key_value_storage.dart';
import 'package:my_project/models/app_user.dart';
import 'package:my_project/repositories/auth_repository.dart';
import 'package:my_project/services/api_client.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._apiClient, this._storage);

  final ApiClient _apiClient;
  final KeyValueStorage _storage;
  static const String _currentUserKey = 'current_user';

  Future<void> _cacheUser(AppUser user) async {
    await _storage.writeString(
      key: _currentUserKey,
      value: jsonEncode(user.toJson()),
    );
  }

  @override
  Future<void> register({required AppUser user}) async {
    final (registeredUser, _) = await _apiClient.register(
      name: user.name,
      email: user.email,
      password: user.password,
    );
    await _cacheUser(registeredUser);
  }

  @override
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final (user, _) = await _apiClient.login(
      email: email,
      password: password,
    );
    await _cacheUser(user);
    return true;
  }

  @override
  Future<void> logout() async {
    await _apiClient.logout();
    await _storage.remove(key: _currentUserKey);
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      final user = await _apiClient.getMe();
      if (user != null) {
        await _cacheUser(user);
        return user;
      }
      return null;
    } catch (_) {
      final cached = await _storage.readString(key: _currentUserKey);
      if (cached != null) {
        return AppUser.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }
      return null;
    }
  }

  @override
  Future<void> updateCurrentUser({required AppUser user}) async {
    await _cacheUser(user);
  }

  @override
  Future<void> deleteCurrentUser() async {
    await _apiClient.logout();
    await _storage.remove(key: _currentUserKey);
  }
}
