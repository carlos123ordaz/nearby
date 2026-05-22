import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import 'models/conversation_model.dart';
import 'models/message_model.dart';

class ChatRepository {
  final SupabaseClient _client;

  ChatRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<String> getOrCreateConversation(String otherUserId) async {
    // Check existing conversation
    final existing = await _client
        .from(SupabaseConstants.conversationsTable)
        .select('id')
        .or('and(user_a.eq.$_userId,user_b.eq.$otherUserId),and(user_a.eq.$otherUserId,user_b.eq.$_userId)')
        .maybeSingle();

    if (existing != null) return existing['id'] as String;

    // Create new conversation
    final result = await _client
        .from(SupabaseConstants.conversationsTable)
        .insert({
          'user_a': _userId,
          'user_b': otherUserId,
        })
        .select('id')
        .single();

    return result['id'] as String;
  }

  Future<List<ConversationModel>> getConversations() async {
    final data = await _client
        .from(SupabaseConstants.conversationsTable)
        .select('''
          *,
          user_a_profile:profiles!conversations_user_a_fkey(
            id, display_name, username, avatar_url, status
          ),
          user_b_profile:profiles!conversations_user_b_fkey(
            id, display_name, username, avatar_url, status
          ),
          messages(id, sender_id, content, read_at, created_at)
        ''')
        .or('user_a.eq.$_userId,user_b.eq.$_userId')
        .order('updated_at', ascending: false);

    return (data as List)
        .map((d) {
          // Sort messages by created_at desc and take first
          final msgs = d['messages'] as List<dynamic>? ?? [];
          msgs.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
          return ConversationModel.fromJson({...d, 'messages': msgs}, _userId);
        })
        .toList();
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    final data = await _client
        .from(SupabaseConstants.messagesTable)
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (data as List).map((d) => MessageModel.fromJson(d)).toList();
  }

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final result = await _client
        .from(SupabaseConstants.messagesTable)
        .insert({
          'conversation_id': conversationId,
          'sender_id': _userId,
          'content': content,
        })
        .select()
        .single();

    // Update conversation updated_at
    await _client
        .from(SupabaseConstants.conversationsTable)
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);

    return MessageModel.fromJson(result);
  }

  Future<void> markMessagesRead(String conversationId) async {
    await _client
        .from(SupabaseConstants.messagesTable)
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', conversationId)
        .neq('sender_id', _userId)
        .isFilter('read_at', null);
  }

  RealtimeChannel subscribeToMessages({
    required String conversationId,
    required void Function(MessageModel) onNewMessage,
  }) {
    return _client
        .channel('${SupabaseConstants.messagesChannel}_$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConstants.messagesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final msg = MessageModel.fromJson(payload.newRecord);
            onNewMessage(msg);
          },
        )
        .subscribe();
  }
}
