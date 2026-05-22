import '../../../../shared/models/profile_model.dart';
import 'message_model.dart';

class ConversationModel {
  final String id;
  final String userA;
  final String userB;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProfileModel? otherProfile;
  final MessageModel? lastMessage;
  final int unreadCount;

  const ConversationModel({
    required this.id,
    required this.userA,
    required this.userB,
    required this.createdAt,
    required this.updatedAt,
    this.otherProfile,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json, String myUserId) {
    final isUserA = json['user_a'] == myUserId;
    final otherProfileData = isUserA
        ? json['user_b_profile'] as Map<String, dynamic>?
        : json['user_a_profile'] as Map<String, dynamic>?;

    ProfileModel? otherProfile;
    if (otherProfileData != null) {
      otherProfile = ProfileModel.fromJson({
        ...otherProfileData,
        'age': null,
        'is_discoverable': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    final msgs = json['messages'] as List<dynamic>?;
    MessageModel? lastMessage;
    int unreadCount = 0;

    if (msgs != null && msgs.isNotEmpty) {
      lastMessage = MessageModel.fromJson(msgs.first as Map<String, dynamic>);
      unreadCount = msgs
          .where((m) =>
              (m as Map<String, dynamic>)['sender_id'] != myUserId &&
              m['read_at'] == null)
          .length;
    }

    return ConversationModel(
      id: json['id'] as String,
      userA: json['user_a'] as String,
      userB: json['user_b'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      otherProfile: otherProfile,
      lastMessage: lastMessage,
      unreadCount: unreadCount,
    );
  }

  String otherUserId(String myId) => userA == myId ? userB : userA;
}
