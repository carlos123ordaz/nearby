import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/chat_repository.dart';
import '../data/models/conversation_model.dart';
import '../data/models/message_model.dart';
import '../../auth/providers/auth_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(supabaseClientProvider));
});

// ─── Unread count for badge ────────────────────────────────────────────────

final unreadChatsCountProvider = StateProvider<int>((ref) => 0);

// ─── Chat messages for a specific conversation ────────────────────────────

class MessagesNotifier extends StateNotifier<List<MessageModel>> {
  final ChatRepository _repo;
  final String conversationId;
  RealtimeChannel? _channel;

  MessagesNotifier(this._repo, this.conversationId) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final messages = await _repo.getMessages(conversationId);
    state = messages;
    await _repo.markMessagesRead(conversationId);
  }

  void _subscribe() {
    _channel = _repo.subscribeToMessages(
      conversationId: conversationId,
      onNewMessage: (msg) {
        if (!state.any((m) => m.id == msg.id)) {
          state = [...state, msg];
        }
        _repo.markMessagesRead(conversationId);
      },
    );
  }

  Future<void> sendMessage(String content) async {
    final msg = await _repo.sendMessage(
      conversationId: conversationId,
      content: content,
    );
    if (!state.any((m) => m.id == msg.id)) {
      state = [...state, msg];
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final messagesProvider = StateNotifierProvider.family<MessagesNotifier, List<MessageModel>, String>(
  (ref, conversationId) {
    final repo = ref.watch(chatRepositoryProvider);
    final notifier = MessagesNotifier(repo, conversationId);
    notifier._subscribe();
    return notifier;
  },
);

// ─── Conversations list ────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<AsyncValue<List<ConversationModel>>> {
  final ChatRepository _repo;
  final Ref _ref;

  ChatNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    loadConversations();
  }

  Future<void> loadConversations() async {
    try {
      final convs = await _repo.getConversations();
      state = AsyncValue.data(convs);
      final unread = convs.fold<int>(0, (acc, c) => acc + c.unreadCount);
      _ref.read(unreadChatsCountProvider.notifier).state = unread;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<String?> getOrCreateConversation(String otherUserId) async {
    try {
      final id = await _repo.getOrCreateConversation(otherUserId);
      await loadConversations();
      return id;
    } catch (_) {
      return null;
    }
  }
}

final chatNotifierProvider = StateNotifierProvider<ChatNotifier, AsyncValue<List<ConversationModel>>>((ref) {
  return ChatNotifier(ref.watch(chatRepositoryProvider), ref);
});
