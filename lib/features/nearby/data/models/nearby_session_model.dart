class NearbySessionModel {
  final String id;
  final String userId;
  final String ephemeralBleId;
  final DateTime expiresAt;
  final DateTime createdAt;

  const NearbySessionModel({
    required this.id,
    required this.userId,
    required this.ephemeralBleId,
    required this.expiresAt,
    required this.createdAt,
  });

  factory NearbySessionModel.fromJson(Map<String, dynamic> json) {
    return NearbySessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      ephemeralBleId: json['ephemeral_ble_id'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
