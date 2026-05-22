import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { online, offline, justConnected }

class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  ConnectivityNotifier() : super(ConnectivityStatus.online) {
    _init();
  }

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _reconnectedTimer;

  Future<void> _init() async {
    // Synchronous initial check
    final initial = await Connectivity().checkConnectivity();
    _update(initial);

    _sub = Connectivity().onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final isOnline = results.any((r) => r != ConnectivityResult.none);

    if (!isOnline) {
      _reconnectedTimer?.cancel();
      state = ConnectivityStatus.offline;
    } else if (state == ConnectivityStatus.offline) {
      // Was offline → briefly show "reconnected" banner before hiding
      state = ConnectivityStatus.justConnected;
      _reconnectedTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) state = ConnectivityStatus.online;
      });
    }
    // If already online, do nothing (avoids spurious rebuilds on network switches)
  }

  @override
  void dispose() {
    _sub?.cancel();
    _reconnectedTimer?.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>((ref) {
  return ConnectivityNotifier();
});
