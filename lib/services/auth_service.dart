import 'package:my_project/models/app_user.dart';
import 'package:my_project/repositories/auth_repository.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  AuthService(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = AppUser(
      id: const Uuid().v4(),
      name: name.trim(),
      email: email.trim(),
      password: password,
    );
    await _authRepository.register(user: user);
  }

  Future<bool> login({required String email, required String password}) {
    return _authRepository.login(email: email.trim(), password: password);
  }

  Future<void> logout() {
    return _authRepository.logout();
  }

  Future<AppUser?> getCurrentUser() {
    return _authRepository.getCurrentUser();
  }

  Future<bool> isLoggedIn() async {
    return await getCurrentUser() != null;
  }

  Future<void> updateCurrentUser({
    required String name,
    required String email,
  }) async {
    final user = await getCurrentUser();
    if (user == null) {
      return;
    }

    final updated = user.copyWith(
      name: name.trim(),
      email: email.trim(),
    );
    await _authRepository.updateCurrentUser(user: updated);
  }

  Future<void> deleteCurrentUser() {
    return _authRepository.deleteCurrentUser();
  }
}
