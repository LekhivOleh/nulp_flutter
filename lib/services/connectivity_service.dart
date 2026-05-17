import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final _connectivity = Connectivity();
  bool _isConnected = true;

  late final Stream<bool> connectionStatusStream = _connectivity
      .onConnectivityChanged
      .map((result) {
        final ok = result != ConnectivityResult.none;
        _isConnected = ok;
        return ok;
      })
      .distinct();

  bool get isConnected => _isConnected;

  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    final ok = result != ConnectivityResult.none;
    _isConnected = ok;
    return ok;
  }
}
