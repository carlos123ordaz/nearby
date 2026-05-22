import '../../../../shared/models/profile_model.dart';

class FriendshipModel {
  final String id;
  final String userA;
  final String userB;
  final DateTime createdAt;
  final ProfileModel? friendProfile;

  const FriendshipModel({
    required this.id,
    required this.userA,
    required this.userB,
    required this.createdAt,
    this.friendProfile,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json, String myUserId) {
    final isUserA = json['user_a'] == myUserId;
    final friendData = isUserA
        ? json['user_b_profile'] as Map<String, dynamic>?
        : json['user_a_profile'] as Map<String, dynamic>?;

    ProfileModel? friendProfile;
    if (friendData != null) {
      friendProfile = ProfileModel.fromJson({
        ...friendData,
        'age': null,
        'is_discoverable': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    return FriendshipModel(
      id: json['id'] as String,
      userA: json['user_a'] as String,
      userB: json['user_b'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      friendProfile: friendProfile,
    );
  }

  String friendId(String myId) => userA == myId ? userB : userA;
}
