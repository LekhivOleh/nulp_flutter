import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final _connectivity = Connectivity();
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  Stream<bool> get connectionStatusStream {
    return _connectivity.onConnectivityChanged.map((result) {
      final isConnected = result != ConnectivityResult.none;
      _isConnected = isConnected;
      return isConnected;
    });
  }

  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    final isConnected = result != ConnectivityResult.none;
    _isConnected = isConnected;
    return isConnected;
  }
}
