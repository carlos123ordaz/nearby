class SupabaseConstants {
  SupabaseConstants._();

  // Replace with your actual Supabase project credentials
  static const String supabaseUrl = 'https://btfpcwznehtxasngaeyv.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_02qu9pUHr2czZtAI9YBJLQ_DXPHCS1Q';

  // Tables
  static const String profilesTable = 'profiles';
  static const String nearbySessionsTable = 'nearby_sessions';
  static const String friendRequestsTable = 'friend_requests';
  static const String friendshipsTable = 'friendships';
  static const String conversationsTable = 'conversations';
  static const String messagesTable = 'messages';
  static const String blocksTable = 'blocks';
  static const String reportsTable = 'reports';

  // Realtime channels
  static const String requestsChannel = 'friend_requests_channel';
  static const String messagesChannel = 'messages_channel';
  static const String nearbyPresenceChannel = 'nearby_presence';

  // Storage
  static const String avatarsBucket = 'avatars';
}
