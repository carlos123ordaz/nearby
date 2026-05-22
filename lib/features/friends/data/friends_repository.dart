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
    await _client
        .from(SupabaseConstants.friendRequestsTable)
        .update({'status': 'accepted', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', requestId)
        .eq('receiver_id', _userId);
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
    final data = await _client
        .from(SupabaseConstants.friendRequestsTable)
        .select('''
          *,
          sender_profile:profiles!friend_requests_sender_id_fkey(
            id, display_name, username, avatar_url, interests
          )
        ''')
        .eq('receiver_id', _userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (data as List)
        .map((d) => FriendRequestModel.fromJson({
              ...d,
              'sender_profile': d['sender_profile'],
            }))
        .toList();
  }

  Future<List<FriendRequestModel>> getSentRequests() async {
    final data = await _client
        .from(SupabaseConstants.friendRequestsTable)
        .select('''
          *,
          receiver_profile:profiles!friend_requests_receiver_id_fkey(
            id, display_name, username, avatar_url, interests
          )
        ''')
        .eq('sender_id', _userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (data as List)
        .map((d) => FriendRequestModel.fromJson({
              ...d,
              'receiver_profile': d['receiver_profile'],
            }))
        .toList();
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
    return _client
        .channel(SupabaseConstants.requestsChannel)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConstants.friendRequestsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: _userId,
          ),
          callback: (_) => onNewRequest(),
        )
        .subscribe();
  }

  // ─── Friendships ───────────────────────────────────────────────────────────

  Future<List<FriendshipModel>> getFriends() async {
    final data = await _client
        .from(SupabaseConstants.friendshipsTable)
        .select('''
          *,
          user_a_profile:profiles!friendships_user_a_fkey(
            id, display_name, username, avatar_url, bio, interests, status
          ),
          user_b_profile:profiles!friendships_user_b_fkey(
            id, display_name, username, avatar_url, bio, interests, status
          )
        ''')
        .or('user_a.eq.$_userId,user_b.eq.$_userId')
        .order('created_at', ascending: false);

    return (data as List)
        .map((d) => FriendshipModel.fromJson(d, _userId))
        .toList();
  }

  Future<void> removeFriend(String friendId) async {
    await _client
        .from(SupabaseConstants.friendshipsTable)
        .delete()
        .or('and(user_a.eq.$_userId,user_b.eq.$friendId),and(user_a.eq.$friendId,user_b.eq.$_userId)');
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
