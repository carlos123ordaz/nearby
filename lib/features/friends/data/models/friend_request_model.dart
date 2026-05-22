enum FriendRequestStatus { pending, accepted, rejected, cancelled }

class FriendRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined profile data (optional)
  final String? senderDisplayName;
  final String? senderUsername;
  final String? senderAvatarUrl;
  final List<String> senderInterests;
  final String? receiverDisplayName;
  final String? receiverUsername;
  final String? receiverAvatarUrl;

  const FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.senderDisplayName,
    this.senderUsername,
    this.senderAvatarUrl,
    this.senderInterests = const [],
    this.receiverDisplayName,
    this.receiverUsername,
    this.receiverAvatarUrl,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    FriendRequestStatus parseStatus(String s) {
      return switch (s) {
        'accepted' => FriendRequestStatus.accepted,
        'rejected' => FriendRequestStatus.rejected,
        'cancelled' => FriendRequestStatus.cancelled,
        _ => FriendRequestStatus.pending,
      };
    }

    final senderProfile = json['sender_profile'] as Map<String, dynamic>?;
    final receiverProfile = json['receiver_profile'] as Map<String, dynamic>?;

    return FriendRequestModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      status: parseStatus(json['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.parse(json['created_at'] as String),
      senderDisplayName: senderProfile?['display_name'] as String?,
      senderUsername: senderProfile?['username'] as String?,
      senderAvatarUrl: senderProfile?['avatar_url'] as String?,
      senderInterests: (senderProfile?['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      receiverDisplayName: receiverProfile?['display_name'] as String?,
      receiverUsername: receiverProfile?['username'] as String?,
      receiverAvatarUrl: receiverProfile?['avatar_url'] as String?,
    );
  }
}
