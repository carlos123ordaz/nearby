import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../core/constants/app_constants.dart';

enum BleScanStatus { idle, scanning, error }

class BleScanner {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  BleScanStatus _status = BleScanStatus.idle;
  Timer? _scanTimer;

  BleScanStatus get status => _status;

  /// Starts scanning for BLE devices advertising our service UUID.
  /// Returns a stream of discovered ephemeral BLE IDs.
  Stream<String> startScan() async* {
    if (_status == BleScanStatus.scanning) return;

    final ctrl = StreamController<String>();

    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _status = BleScanStatus.error;
        ctrl.addError('Bluetooth desactivado');
        await ctrl.close();
        return;
      }

      _status = BleScanStatus.scanning;

      await FlutterBluePlus.startScan(
        withServices: [Guid(AppConstants.bleServiceUuid)],
        timeout: AppConstants.bleScanDuration,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final serviceData = result.advertisementData.serviceData;
          for (final entry in serviceData.entries) {
            if (entry.value.isNotEmpty) {
              // The ephemeral ID is encoded in service data as UTF-8 bytes
              try {
                final ephemeralId = String.fromCharCodes(entry.value);
                if (!ctrl.isClosed) ctrl.add(ephemeralId);
              } catch (_) {}
            }
          }

          // Also try manufacturer data
          final mfgData = result.advertisementData.manufacturerData;
          for (final entry in mfgData.entries) {
            try {
              final ephemeralId = String.fromCharCodes(entry.value);
              if (ephemeralId.length > 10 && !ctrl.isClosed) ctrl.add(ephemeralId);
            } catch (_) {}
          }
        }
      });

      FlutterBluePlus.isScanning.listen((isScanning) {
        if (!isScanning && _status == BleScanStatus.scanning) {
          _status = BleScanStatus.idle;
          if (!ctrl.isClosed) ctrl.close();
        }
      });

      yield* ctrl.stream;
    } catch (e) {
      _status = BleScanStatus.error;
      ctrl.addError(e);
      await ctrl.close();
    }
  }

  Future<void> stopScan() async {
    _scanTimer?.cancel();
    _scanSubscription?.cancel();
    _status = BleScanStatus.idle;
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
  }

  Future<bool> isBluetoothOn() async {
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  void dispose() {
    stopScan();
    _adapterSubscription?.cancel();
  }
}
