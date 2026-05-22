// BLE Advertising Note:
// Flutter does not have a stable cross-platform BLE advertising package.
// On Android, we use a native platform channel to start/stop advertising.
// On iOS, advertising as a peripheral requires special entitlements and
// works differently — for this MVP we use Supabase Realtime presence as fallback.
//
// The native Android code must be added in MainActivity.kt (see SETUP.md).

import 'package:flutter/services.dart';

class BleAdvertiser {
  static const _channel = MethodChannel('com.nearby.app/ble_advertiser');

  bool _isAdvertising = false;
  bool get isAdvertising => _isAdvertising;

  /// Attempt to start BLE advertising with the given ephemeral ID as service data.
  /// Returns true if advertising started, false if not supported or failed.
  Future<bool> startAdvertising(String ephemeralId) async {
    try {
      final result = await _channel.invokeMethod<bool>('startAdvertising', {
        'serviceUuid': '4fafc201-1fb5-459e-8fcc-c5c9c331914b',
        'ephemeralId': ephemeralId,
      });
      _isAdvertising = result ?? false;
      return _isAdvertising;
    } on PlatformException catch (e) {
      // Advertising not supported or permission denied
      _isAdvertising = false;
      return false;
    } catch (_) {
      _isAdvertising = false;
      return false;
    }
  }

  Future<void> stopAdvertising() async {
    try {
      await _channel.invokeMethod('stopAdvertising');
    } catch (_) {}
    _isAdvertising = false;
  }

  /// Checks if BLE advertising is supported on this device.
  Future<bool> isSupported() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAdvertisingSupported');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
