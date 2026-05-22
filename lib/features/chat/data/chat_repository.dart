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
    final rows = await _client
        .from(SupabaseConstants.conversationsTable)
        .select('id, user_a, user_b, created_at, updated_at')
        .or('user_a.eq.$_userId,user_b.eq.$_userId')
        .order('updated_at', ascending: false);

    if ((rows as List).isEmpty) return [];

    final otherIds = rows.map<String>((r) {
      return r['user_a'] == _userId ? r['user_b'] as String : r['user_a'] as String;
    }).toList();

    final profileRows = await _client
        .from(SupabaseConstants.profilesTable)
        .select('id, display_name, username, avatar_url, status')
        .inFilter('id', otherIds);

    final profileMap = <String, Map<String, dynamic>>{
      for (final p in (profileRows as List))
        p['id'] as String: p as Map<String, dynamic>,
    };

    final convIds = rows.map<String>((r) => r['id'] as String).toList();

    final msgRows = await _client
        .from(SupabaseConstants.messagesTable)
        .select('id, conversation_id, sender_id, content, read_at, created_at')
        .inFilter('conversation_id', convIds)
        .order('created_at', ascending: false);

    final msgsMap = <String, List<Map<String, dynamic>>>{};
    for (final m in (msgRows as List)) {
      final cid = m['conversation_id'] as String;
      msgsMap.putIfAbsent(cid, () => []).add(m as Map<String, dynamic>);
    }

    return rows.map<ConversationModel>((r) {
      final isUserA = r['user_a'] == _userId;
      final otherId = isUserA ? r['user_b'] as String : r['user_a'] as String;
      final profileData = profileMap[otherId];
      final msgs = msgsMap[r['id']] ?? [];

      return ConversationModel.fromJson({
        'id': r['id'],
        'user_a': r['user_a'],
        'user_b': r['user_b'],
        'created_at': r['created_at'],
        'updated_at': r['updated_at'],
        'user_a_profile': isUserA ? null : profileData,
        'user_b_profile': isUserA ? profileData : null,
        'messages': msgs,
      }, _userId);
    }).toList();
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
