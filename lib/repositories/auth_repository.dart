import 'package:my_project/models/app_user.dart';

abstract class AuthRepository {
  Future<void> register({required AppUser user});
  Future<bool> login({required String email, required String password});
  Future<void> logout();
  Future<AppUser?> getCurrentUser();
  Future<void> updateCurrentUser({required AppUser user});
  Future<void> deleteCurrentUser();
}
