import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_project/models/app_user.dart';
import 'package:my_project/services/auth_service.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authService) : super(AuthInitial());

  final AuthService _authService;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final success = await _authService.login(
        email: email,
        password: password,
      );
      if (isClosed) return;
      if (success) {
        final user = await _authService.getCurrentUser();
        if (!isClosed) emit(AuthAuthenticated(user!));
      } else {
        emit(
          AuthError('Invalid credentials or user not registered.'),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
      }
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      if (!isClosed) emit(AuthRegistrationSuccess());
    } catch (e) {
      if (!isClosed) {
        emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
      }
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    if (!isClosed) emit(AuthUnauthenticated());
  }

  Future<void> loadUser() async {
    emit(AuthLoading());
    final user = await _authService.getCurrentUser();
    if (isClosed) return;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> updateUser({
    required String name,
    required String email,
  }) async {
    emit(AuthLoading());
    try {
      await _authService.updateCurrentUser(name: name, email: email);
      final user = await _authService.getCurrentUser();
      if (!isClosed) {
        emit(
          AuthAuthenticated(
            user!,
            successMessage: 'Profile updated successfully.',
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
      }
    }
  }

  Future<void> deleteUser() async {
    await _authService.deleteCurrentUser();
    if (!isClosed) emit(AuthUnauthenticated());
  }
}
