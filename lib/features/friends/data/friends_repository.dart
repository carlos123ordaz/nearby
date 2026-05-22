import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../shared/models/profile_model.dart';
import 'models/friend_request_model.dart';
import 'models/friendship_model.dart';

class FriendsRepository {
  final SupabaseClient _client;

  FriendsRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  // ─── Friend Requests ───────────────────────────────────────────────────────

  Future<FriendRequestModel> sendRequest(String receiverId) async {
    final result = await _client
        .from(SupabaseConstants.friendRequestsTable)
        .insert({
          'sender_id': _userId,
          'receiver_id': receiverId,
          'status': 'pending',
        })
        .select()
        .single();
    return FriendRequestModel.fromJson(result);
  }

  Future<void> acceptRequest(String requestId) async {
    final result = await _client
        .from(SupabaseConstants.friendRequestsTable)
        .update({'status': 'accepted', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', requestId)
        .eq('receiver_id', _userId)
        .select('sender_id')
        .single();

    final senderId = result['sender_id'] as String;

    await _client
        .from(SupabaseConstants.friendshipsTable)
        .insert({'user_a': senderId, 'user_b': _userId});
  }

  Future<void> rejectRequest(String requestId) async {
    await _client
        .from(SupabaseConstants.friendRequestsTable)
        .update({'status': 'rejected', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', requestId)
        .eq('receiver_id', _userId);
  }

  Future<void> cancelRequest(String receiverId) async {
    await _client
        .from(SupabaseConstants.friendRequestsTable)
        .update({'status': 'cancelled', 'updated_at': DateTime.now().toIso8601String()})
        .eq('sender_id', _userId)
        .eq('receiver_id', receiverId)
        .eq('status', 'pending');
  }

  Future<List<FriendRequestModel>> getReceivedRequests() async {
    final rows = await _client
        .from(SupabaseConstants.friendRequestsTable)
        .select('id, sender_id, receiver_id, status, created_at, updated_at')
        .eq('receiver_id', _userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    if ((rows as List).isEmpty) return [];

    final senderIds = rows.map<String>((r) => r['sender_id'] as String).toList();
    final profileRows = await _client
        .from(SupabaseConstants.profilesTable)
        .select('id, display_name, username, avatar_url, interests')
        .inFilter('id', senderIds);

    final profileMap = <String, Map<String, dynamic>>{
      for (final p in (profileRows as List))
        p['id'] as String: p as Map<String, dynamic>,
    };

    return rows.map<FriendRequestModel>((r) {
      return FriendRequestModel.fromJson({
        ...r,
        'sender_profile': profileMap[r['sender_id']],
      });
    }).toList();
  }

  Future<List<FriendRequestModel>> getSentRequests() async {
    final rows = await _client
        .from(SupabaseConstants.friendRequestsTable)
        .select('id, sender_id, receiver_id, status, created_at, updated_at')
        .eq('sender_id', _userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    if ((rows as List).isEmpty) return [];

    final receiverIds = rows.map<String>((r) => r['receiver_id'] as String).toList();
    final profileRows = await _client
        .from(SupabaseConstants.profilesTable)
        .select('id, display_name, username, avatar_url, interests')
        .inFilter('id', receiverIds);

    final profileMap = <String, Map<String, dynamic>>{
      for (final p in (profileRows as List))
        p['id'] as String: p as Map<String, dynamic>,
    };

    return rows.map<FriendRequestModel>((r) {
      return FriendRequestModel.fromJson({
        ...r,
        'receiver_profile': profileMap[r['receiver_id']],
      });
    }).toList();
  }

  Future<FriendRequestStatus?> getRequestStatus(String otherUserId) async {
    final data = await _client
        .from(SupabaseConstants.friendRequestsTable)
        .select('status')
        .or('and(sender_id.eq.$_userId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$_userId)')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return switch (data['status'] as String) {
      'accepted' => FriendRequestStatus.accepted,
      'rejected' => FriendRequestStatus.rejected,
      'cancelled' => FriendRequestStatus.cancelled,
      _ => FriendRequestStatus.pending,
    };
  }

  RealtimeChannel subscribeToRequests({
    required void Function() onNewRequest,
  }) {
    final channel = _client.channel(SupabaseConstants.requestsChannel);

    // New request received
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: SupabaseConstants.friendRequestsTable,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'receiver_id',
        value: _userId,
      ),
      callback: (_) => onNewRequest(),
    );

    // Sent request accepted/rejected by the other person
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: SupabaseConstants.friendRequestsTable,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'sender_id',
        value: _userId,
      ),
      callback: (_) => onNewRequest(),
    );

    return channel.subscribe();
  }

  // ─── Friendships ───────────────────────────────────────────────────────────

  Future<List<FriendshipModel>> getFriends() async {
    final rows = await _client
        .from(SupabaseConstants.friendshipsTable)
        .select('id, user_a, user_b, created_at')
        .or('user_a.eq.$_userId,user_b.eq.$_userId')
        .order('created_at', ascending: false);

    if ((rows as List).isEmpty) return [];

    final friendIds = rows.map<String>((r) =>
        r['user_a'] == _userId ? r['user_b'] as String : r['user_a'] as String).toList();

    final profileRows = await _client
        .from(SupabaseConstants.profilesTable)
        .select('id, display_name, username, avatar_url, bio, interests, status')
        .inFilter('id', friendIds);

    final profileMap = <String, Map<String, dynamic>>{
      for (final p in (profileRows as List))
        p['id'] as String: p as Map<String, dynamic>,
    };

    return rows.map<FriendshipModel>((r) {
      final isUserA = r['user_a'] == _userId;
      final friendId = isUserA ? r['user_b'] as String : r['user_a'] as String;
      final profileData = profileMap[friendId];
      return FriendshipModel.fromJson({
        'id': r['id'],
        'user_a': r['user_a'],
        'user_b': r['user_b'],
        'created_at': r['created_at'],
        'user_a_profile': isUserA ? null : profileData,
        'user_b_profile': isUserA ? profileData : null,
      }, _userId);
    }).toList();
  }

  Future<void> removeFriend(String friendId) async {
    await _client
        .from(SupabaseConstants.friendshipsTable)
        .delete()
        .or('and(user_a.eq.$_userId,user_b.eq.$friendId),and(user_a.eq.$friendId,user_b.eq.$_userId)');

    // Reset the old accepted request so the user can send a new one later.
    await _client
        .from(SupabaseConstants.friendRequestsTable)
        .delete()
        .or('and(sender_id.eq.$_userId,receiver_id.eq.$friendId),and(sender_id.eq.$friendId,receiver_id.eq.$_userId)');
  }

  Future<bool> areFriends(String otherUserId) async {
    final data = await _client
        .from(SupabaseConstants.friendshipsTable)
        .select('id')
        .or('and(user_a.eq.$_userId,user_b.eq.$otherUserId),and(user_a.eq.$otherUserId,user_b.eq.$_userId)')
        .maybeSingle();
    return data != null;
  }

  // ─── Blocks & Reports ──────────────────────────────────────────────────────

  Future<void> blockUser(String targetId) async {
    await _client.from(SupabaseConstants.blocksTable).insert({
      'blocker_id': _userId,
      'blocked_id': targetId,
    });
    // Also remove any friendship
    await removeFriend(targetId);
  }

  Future<void> reportUser(String targetId, {required String reason, String? description}) async {
    await _client.from(SupabaseConstants.reportsTable).insert({
      'reporter_id': _userId,
      'reported_id': targetId,
      'reason': reason,
      'description': description,
    });
  }
}
