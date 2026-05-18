import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

enum ConnectivityStatus { online, offline, loading }

@riverpod
class ConnectivityNotifier extends _$ConnectivityNotifier {
  @override
  Stream<ConnectivityStatus> build() async* {
    yield ConnectivityStatus.loading;
    
    final connectivity = Connectivity();
    
    // Initial check
    try {
      final result = await connectivity.checkConnectivity();
      yield _mapResultToStatus(result);
    } catch (e) {
      yield ConnectivityStatus.offline;
    }
    
    // Watch for changes
    try {
      await for (final result in connectivity.onConnectivityChanged) {
        yield _mapResultToStatus(result);
      }
    } catch (e) {
      yield ConnectivityStatus.offline;
    }
  }

  ConnectivityStatus _mapResultToStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }
    return ConnectivityStatus.online;
  }
}
