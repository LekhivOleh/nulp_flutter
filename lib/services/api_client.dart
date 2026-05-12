import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:my_project/models/app_user.dart';
import 'package:my_project/services/api_endpoints.dart';
import 'package:my_project/services/secure_token_storage.dart';

class ApiClient {
  ApiClient(this._tokenStorage);

  static String get baseUrl => ApiEndpoints.apiBaseUrl;
  final SecureTokenStorage _tokenStorage;
  String? _cachedToken;

  Future<String?> _getToken() async {
    _cachedToken ??= await _tokenStorage.getToken();
    return _cachedToken;
  }

  Future<void> _setToken(String token) async {
    _cachedToken = token;
    await _tokenStorage.saveToken(token);
  }

  Map<String, String> _getHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_cachedToken != null) {
      headers['Authorization'] = 'Bearer $_cachedToken';
    }
    return headers;
  }

  bool get isAuthenticated => _cachedToken != null;

  Future<void> loadToken() async {
    _cachedToken = await _tokenStorage.getToken();
  }

  Future<(AppUser, String)> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _getHeaders(),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body)['error'] as String?
          ?? 'Registration failed';
      throw Exception(err);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String;
    await _setToken(token);
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    return (user, token);
  }

  Future<(AppUser, String)> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _getHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode != 200) {
      throw Exception('Invalid credentials');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String;
    await _setToken(token);
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    return (user, token);
  }

  Future<AppUser?> getMe() async {
    final token = await _getToken();
    if (token == null) return null;
    final response = await http.get(
      Uri.parse('$baseUrl/user/me'),
      headers: _getHeaders(),
    );
    if (response.statusCode != 200) return null;
    return AppUser.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> logout() async {
    _cachedToken = null;
    await _tokenStorage.deleteToken();
  }

  Future<void> registerCard(String cardId) async {
    await _getToken();
    final response = await http.post(
      Uri.parse(
        '$baseUrl/user/register-card?cardId=${Uri.encodeQueryComponent(cardId)}',
      ),
      headers: _getHeaders(),
    );
    if (response.statusCode != 200) {
      final err =
          jsonDecode(response.body)['error'] as String? ?? 'Unknown error';
      throw Exception('Card registration failed: $err');
    }
  }
}
