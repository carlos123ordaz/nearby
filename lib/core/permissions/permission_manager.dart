import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static Future<bool> requestBlePermissions() async {
    if (!Platform.isAndroid) return true;

    final sdkInt = await _getAndroidSdkInt();

    if (sdkInt >= 31) {
      // Android 12+
      final results = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ].request();

      return results.values.every((s) => s.isGranted);
    } else {
      // Android < 12
      final results = await [
        Permission.bluetooth,
        Permission.locationWhenInUse,
      ].request();

      return results.values.every((s) => s.isGranted);
    }
  }

  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<BlePermissionStatus> checkBleStatus() async {
    if (!Platform.isAndroid) return BlePermissionStatus.granted;

    final sdkInt = await _getAndroidSdkInt();

    if (sdkInt >= 31) {
      final scan = await Permission.bluetoothScan.status;
      final connect = await Permission.bluetoothConnect.status;
      final advertise = await Permission.bluetoothAdvertise.status;

      if (scan.isGranted && connect.isGranted && advertise.isGranted) {
        return BlePermissionStatus.granted;
      }
      if (scan.isPermanentlyDenied || connect.isPermanentlyDenied) {
        return BlePermissionStatus.permanentlyDenied;
      }
      return BlePermissionStatus.denied;
    } else {
      final bluetooth = await Permission.bluetooth.status;
      final location = await Permission.locationWhenInUse.status;

      if (bluetooth.isGranted && location.isGranted) return BlePermissionStatus.granted;
      if (bluetooth.isPermanentlyDenied || location.isPermanentlyDenied) {
        return BlePermissionStatus.permanentlyDenied;
      }
      return BlePermissionStatus.denied;
    }
  }

  static Future<int> _getAndroidSdkInt() async {
    // Read Android SDK version from system properties
    try {
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(result.stdout.toString().trim()) ?? 33;
    } catch (_) {
      return 33; // Default to Android 13
    }
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}

enum BlePermissionStatus { granted, denied, permanentlyDenied }
