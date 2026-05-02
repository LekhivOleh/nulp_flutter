import 'dart:convert';

import 'package:my_project/data/local/key_value_storage.dart';
import 'package:my_project/models/app_user.dart';
import 'package:my_project/repositories/auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._storage);

  final KeyValueStorage _storage;

  static const String _usersKey = 'registered_users';
  static const String _currentUserEmailKey = 'current_user_email';

  Future<List<AppUser>> _getAllUsers() async {
    final raw = await _storage.readString(key: _usersKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((u) => AppUser.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> register({required AppUser user}) async {
    final users = await _getAllUsers();

    if (users.any((u) => u.email == user.email)) {
      throw Exception('User with this email already exists');
    } 

    users.add(user);
    await _storage.writeString(
      key: _usersKey,
      value: jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  @override
  Future<bool> login({required String email, required String password}) async {
    final users = await _getAllUsers();
    final user = users.firstWhere(
      (u) =>u.email == email && u.password == password,
      orElse: () => throw Exception('Invalid email or password'),
    );

    await _storage.writeString(key: _currentUserEmailKey, value: user.email);
    return true;
  }

  @override
  Future<void> logout() async {
    await _storage.remove(key: _currentUserEmailKey);
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final email = await _storage.readString(key: _currentUserEmailKey);

    if (email == null) {
      return null;
    }

    final users = await _getAllUsers();
    return users.firstWhere(
      (u) => u.email == email,
      orElse: () => throw Exception('User not found')
    );
  }

  @override
  Future<void> updateCurrentUser({required AppUser user}) async {
    final users = await _getAllUsers();
    final index = users.indexWhere((u) => u.email == user.email);
    
    if (index == -1) return; // User not found
    
    users[index] = user;
    await _storage.writeString(
      key: _usersKey,
      value: jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  @override
  Future<void> deleteCurrentUser() async {
    final email = await _storage.readString(key: _currentUserEmailKey);
    if (email == null) {
      return;
    }

    final users = await _getAllUsers();
    users.removeWhere((u) => u.email == email);

    await _storage.writeString(
      key: _usersKey,
      value: jsonEncode(users.map((u) => u.toJson()).toList()),
    );

    await _storage.remove(key: _currentUserEmailKey);
  }

  // admin
  Future<List<AppUser>> getAllUsers() async => _getAllUsers();
}
