import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/friends_repository.dart';
import '../data/models/friend_request_model.dart';
import '../data/models/friendship_model.dart';
import '../../auth/providers/auth_provider.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(ref.watch(supabaseClientProvider));
});

// ─── Pending request count for badge ──────────────────────────────────────

final pendingRequestsCountProvider = StateProvider<int>((ref) => 0);

// ─── Friend request state for a specific user ─────────────────────────────

final friendRequestStateProvider = FutureProvider.family<FriendRequestStatus?, String>((ref, userId) async {
  return ref.watch(friendsRepositoryProvider).getRequestStatus(userId);
});

// ─── Main friends state notifier ──────────────────────────────────────────

class FriendsState {
  final List<FriendshipModel> friends;
  final List<FriendRequestModel> receivedRequests;
  final List<FriendRequestModel> sentRequests;
  final bool isLoading;
  final String? error;

  const FriendsState({
    this.friends = const [],
    this.receivedRequests = const [],
    this.sentRequests = const [],
    this.isLoading = false,
    this.error,
  });

  FriendsState copyWith({
    List<FriendshipModel>? friends,
    List<FriendRequestModel>? receivedRequests,
    List<FriendRequestModel>? sentRequests,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      receivedRequests: receivedRequests ?? this.receivedRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FriendsNotifier extends StateNotifier<FriendsState> {
  final FriendsRepository _repo;
  final Ref _ref;
  RealtimeChannel? _requestsChannel;

  FriendsNotifier(this._repo, this._ref) : super(const FriendsState()) {
    _init();
  }

  Future<void> _init() async {
    await loadAll();
    _subscribeToRequests();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final friends = await _repo.getFriends();
      final received = await _repo.getReceivedRequests();
      final sent = await _repo.getSentRequests();
      state = state.copyWith(
        friends: friends,
        receivedRequests: received,
        sentRequests: sent,
        isLoading: false,
      );
      _ref.read(pendingRequestsCountProvider.notifier).state = received.length;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _subscribeToRequests() {
    _requestsChannel = _repo.subscribeToRequests(onNewRequest: () {
      loadAll();
    });
  }

  Future<bool> sendRequest(String receiverId) async {
    try {
      await _repo.sendRequest(receiverId);
      await loadAll();
      _ref.invalidate(friendRequestStateProvider(receiverId));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      await _repo.acceptRequest(requestId);
      await loadAll();
    } catch (_) {}
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      await _repo.rejectRequest(requestId);
      await loadAll();
    } catch (_) {}
  }

  Future<void> cancelRequest(String receiverId) async {
    try {
      await _repo.cancelRequest(receiverId);
      await loadAll();
      _ref.invalidate(friendRequestStateProvider(receiverId));
    } catch (_) {}
  }

  Future<void> removeFriend(String friendId) async {
    try {
      await _repo.removeFriend(friendId);
      await loadAll();
    } catch (_) {}
  }

  Future<void> blockUser(String targetId) async {
    try {
      await _repo.blockUser(targetId);
      await loadAll();
    } catch (_) {}
  }

  Future<void> reportUser(String targetId, {required String reason}) async {
    await _repo.reportUser(targetId, reason: reason);
  }

  @override
  void dispose() {
    _requestsChannel?.unsubscribe();
    super.dispose();
  }
}

final friendsNotifierProvider = StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  return FriendsNotifier(ref.watch(friendsRepositoryProvider), ref);
});
