import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/profile_model.dart';
import '../data/nearby_repository.dart';
import '../data/models/nearby_session_model.dart';
import '../ble/ble_scanner.dart';
import '../ble/ble_advertiser.dart';
import '../../auth/providers/auth_provider.dart';

final nearbyRepositoryProvider = Provider<NearbyRepository>((ref) {
  return NearbyRepository(ref.watch(supabaseClientProvider));
});

enum NearbyMode { off, active }
enum NearbyDiscoveryMethod { ble, realtime, hybrid }

class NearbyState {
  final NearbyMode mode;
  final List<ProfileModel> nearbyUsers;
  final bool isScanning;
  final String? error;
  final NearbyDiscoveryMethod discoveryMethod;
  final NearbySessionModel? session;

  const NearbyState({
    this.mode = NearbyMode.off,
    this.nearbyUsers = const [],
    this.isScanning = false,
    this.error,
    this.discoveryMethod = NearbyDiscoveryMethod.realtime,
    this.session,
  });

  NearbyState copyWith({
    NearbyMode? mode,
    List<ProfileModel>? nearbyUsers,
    bool? isScanning,
    String? error,
    NearbyDiscoveryMethod? discoveryMethod,
    NearbySessionModel? session,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return NearbyState(
      mode: mode ?? this.mode,
      nearbyUsers: nearbyUsers ?? this.nearbyUsers,
      isScanning: isScanning ?? this.isScanning,
      error: clearError ? null : (error ?? this.error),
      discoveryMethod: discoveryMethod ?? this.discoveryMethod,
      session: clearSession ? null : (session ?? this.session),
    );
  }
}

class NearbyNotifier extends StateNotifier<NearbyState> {
  final NearbyRepository _repo;
  final BleScanner _scanner;
  final BleAdvertiser _advertiser;

  StreamSubscription<String>? _bleScanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  RealtimeChannel? _presenceChannel;
  Timer? _refreshTimer;
  final Set<String> _resolvedIds = {};

  NearbyNotifier(this._repo)
      : _scanner = BleScanner(),
        _advertiser = BleAdvertiser(),
        super(const NearbyState());

  Future<void> activate() async {
    if (state.mode == NearbyMode.active) return;

    state = state.copyWith(mode: NearbyMode.active, isScanning: true, clearError: true);

    try {
      // Create a Supabase session with ephemeral BLE ID and mark as discoverable
      final session = await _repo.createSession();
      await _repo.setDiscoverable(true);
      state = state.copyWith(session: session);

      // Try BLE advertising
      final bleSupported = await _advertiser.isSupported();
      bool bleStarted = false;

      if (bleSupported) {
        bleStarted = await _advertiser.startAdvertising(session.ephemeralBleId);
      }

      // Start BLE scanning
      if (bleStarted || await _scanner.isBluetoothOn()) {
        _startBleScanning();
        state = state.copyWith(discoveryMethod: NearbyDiscoveryMethod.hybrid);
      }

      // Always use Realtime presence as primary/fallback
      _startRealtimePresence();

      if (!bleStarted) {
        state = state.copyWith(discoveryMethod: NearbyDiscoveryMethod.realtime);
      }

      state = state.copyWith(isScanning: false);

      // Periodic rescan
      _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (state.mode == NearbyMode.active) _startBleScanning();
      });

      // Auto-deactivate if the user turns off Bluetooth while nearby mode is active
      _adapterSubscription?.cancel();
      _adapterSubscription = FlutterBluePlus.adapterState.listen((adapterState) {
        if (adapterState != BluetoothAdapterState.on && state.mode == NearbyMode.active) {
          deactivate().then((_) {
            if (mounted) {
              state = state.copyWith(
                error: 'Bluetooth desactivado. Modo cerca desactivado.',
              );
            }
          });
        }
      });
    } catch (e) {
      state = state.copyWith(
        mode: NearbyMode.off,
        isScanning: false,
        error: 'Error al activar modo cercano: $e',
        clearSession: true,
      );
    }
  }

  void _startBleScanning() {
    _bleScanSubscription?.cancel();
    _bleScanSubscription = _scanner.startScan().listen(
      (ephemeralId) async {
        if (_resolvedIds.contains(ephemeralId)) return;
        _resolvedIds.add(ephemeralId);

        final profile = await _repo.resolveEphemeralId(ephemeralId);
        if (profile != null && mounted) {
          final existing = state.nearbyUsers.where((u) => u.id == profile.id).isEmpty;
          if (existing) {
            state = state.copyWith(
              nearbyUsers: [...state.nearbyUsers, profile],
            );
          }
        }
      },
      onError: (_) {},
    );
  }

  void _startRealtimePresence() {
    _presenceChannel?.unsubscribe();
    _presenceChannel = _repo.subscribeToNearbyPresence(
      onNearbyUpdated: (profiles) {
        if (mounted) {
          // Merge with BLE discovered users
          final bleUsers = state.nearbyUsers;
          final merged = <String, ProfileModel>{};
          for (final u in bleUsers) {
            merged[u.id] = u;
          }
          for (final u in profiles) {
            merged[u.id] = u;
          }
          state = state.copyWith(nearbyUsers: merged.values.toList());
        }
      },
    );
  }

  Future<void> deactivate() async {
    _refreshTimer?.cancel();
    _bleScanSubscription?.cancel();
    _adapterSubscription?.cancel();
    await _scanner.stopScan();
    await _advertiser.stopAdvertising();
    _presenceChannel?.unsubscribe();
    await _repo.setDiscoverable(false);
    await _repo.deleteSession();
    _resolvedIds.clear();

    state = NearbyState();
  }

  Future<void> toggle() async {
    if (state.mode == NearbyMode.active) {
      await deactivate();
    } else {
      await activate();
    }
  }

  @override
  void dispose() {
    deactivate();
    super.dispose();
  }
}

final nearbyNotifierProvider = StateNotifierProvider<NearbyNotifier, NearbyState>((ref) {
  return NearbyNotifier(ref.watch(nearbyRepositoryProvider));
});
