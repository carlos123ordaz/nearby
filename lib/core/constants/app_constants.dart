class AppConstants {
  AppConstants._();

  static const String appName = 'Nearby';
  static const String packageName = 'com.nearby.app';
  static const String version = '1.0.0';

  // BLE
  static const String bleServiceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const Duration bleEphemeralRotationInterval = Duration(minutes: 15);
  static const Duration bleScanDuration = Duration(seconds: 10);
  static const Duration nearbySessionExpiry = Duration(hours: 2);

  // Storage
  static const String avatarBucket = 'avatars';
  static const String secureStorageKeySession = 'supabase_session';

  // UI
  static const double bottomNavHeight = 64;
  static const double cardRadius = 16;
  static const double screenPadding = 20;
  static const int maxBioLength = 160;
  static const int maxInterests = 10;

  // Distance labels
  static const Map<String, String> distanceLabels = {
    'very_near': 'Muy cerca',
    'near': 'Cerca',
    'area': 'En el área',
  };
}
