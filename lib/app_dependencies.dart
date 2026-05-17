import 'package:my_project/data/local/key_value_storage.dart';
import 'package:my_project/data/local/shared_preferences_storage.dart';
import 'package:my_project/repositories/api_auth_repository.dart';
import 'package:my_project/repositories/api_log_repository.dart';
import 'package:my_project/repositories/auth_repository.dart';
import 'package:my_project/repositories/log_repository.dart';
import 'package:my_project/services/api_client.dart';
import 'package:my_project/services/auth_service.dart';
import 'package:my_project/services/connectivity_service.dart';
import 'package:my_project/services/log_service.dart';
import 'package:my_project/services/secure_token_storage.dart';
import 'package:my_project/services/ws_log_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDependencies {
  AppDependencies._();

  static final AppDependencies instance = AppDependencies._();

  late final KeyValueStorage _storage;
  late final SecureTokenStorage _tokenStorage;
  late final ApiClient apiClient;
  late final AuthRepository _authRepository;
  late final LogRepository _logRepository;
  late final AuthService authService;
  late final LogService logService;
  late final WsLogSyncService wsLogSyncService;
  late final ConnectivityService connectivityService;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _storage = SharedPreferencesStorage(prefs);
    _tokenStorage = SecureTokenStorage(_storage);
    apiClient = ApiClient(_tokenStorage);
    await apiClient.loadToken();
    _authRepository = ApiAuthRepository(apiClient, _storage);
    _logRepository = ApiLogRepository(_tokenStorage, _storage);
    authService = AuthService(_authRepository);
    logService = LogService(_logRepository);
    wsLogSyncService = WsLogSyncService();
    connectivityService = ConnectivityService();
    await connectivityService.checkConnectivity();
  }
}
