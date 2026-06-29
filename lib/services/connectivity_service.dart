import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();

  final _connectivity = Connectivity();

  /// Stream of connectivity changes — emits `true` when online, `false` offline.
  Stream<bool> get onConnectivityChanged => _connectivity.onConnectivityChanged
      .map((results) => _isConnected(results));

  /// One-shot check of current connectivity status.
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  static bool _isConnected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}

final connectivityService = ConnectivityService._();
