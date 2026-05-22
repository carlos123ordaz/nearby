import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../shared/models/profile_model.dart';
import 'models/nearby_session_model.dart';

class NearbyRepository {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  NearbyRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<NearbySessionModel> createSession() async {
    // Use a 12-char hex ID — short enough to fit in BLE service data (12 bytes)
    // while still unique enough for a session. Full UUID would exceed the 31-byte
    // BLE advertising limit when combined with a 128-bit service UUID.
    final ephemeralId = _uuid.v4().replaceAll('-', '').substring(0, 12);
    final expiresAt = DateTime.now().add(const Duration(hours: 2));

    // Remove old sessions for this user first
    await _client
        .from(SupabaseConstants.nearbySessionsTable)
        .delete()
        .eq('user_id', _userId);

    final result = await _client
        .from(SupabaseConstants.nearbySessionsTable)
        .insert({
          'user_id': _userId,
          'ephemeral_ble_id': ephemeralId,
          'expires_at': expiresAt.toIso8601String(),
        })
        .select()
        .single();

    return NearbySessionModel.fromJson(result);
  }

  Future<void> deleteSession() async {
    await _client
        .from(SupabaseConstants.nearbySessionsTable)
        .delete()
        .eq('user_id', _userId);
  }

  Future<void> setDiscoverable(bool value) async {
    await _client
        .from(SupabaseConstants.profilesTable)
        .update({
          'is_discoverable': value,
          'status': value ? 'active' : 'inactive',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', _userId);
  }

  Future<ProfileModel?> resolveEphemeralId(String ephemeralBleId) async {
    // Look up who owns this ephemeral BLE ID
    final sessionData = await _client
        .from(SupabaseConstants.nearbySessionsTable)
        .select('user_id')
        .eq('ephemeral_ble_id', ephemeralBleId)
        .gt('expires_at', DateTime.now().toIso8601String())
        .maybeSingle();

    if (sessionData == null) return null;
    final userId = sessionData['user_id'] as String;
    if (userId == _userId) return null; // skip self

    final profileData = await _client
        .from(SupabaseConstants.profilesTable)
        .select('id, username, display_name, avatar_url, bio, interests, status, is_discoverable')
        .eq('id', userId)
        .eq('is_discoverable', true)
        .neq('status', 'invisible')
        .maybeSingle();

    if (profileData == null) return null;

    // Check if blocked
    final blocked = await _client
        .from(SupabaseConstants.blocksTable)
        .select('id')
        .or('blocker_id.eq.$_userId,blocked_id.eq.$_userId')
        .or('blocker_id.eq.$userId,blocked_id.eq.$userId')
        .maybeSingle();

    if (blocked != null) return null;

    return ProfileModel.fromJson({
      ...profileData,
      'age': null,
      'is_discoverable': profileData['is_discoverable'] ?? false,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Supabase Realtime presence-based nearby (fallback when BLE advertising unavailable)
  RealtimeChannel subscribeToNearbyPresence({
    required void Function(List<ProfileModel>) onNearbyUpdated,
  }) {
    final channel = _client.channel(SupabaseConstants.nearbyPresenceChannel);

    channel
        .onPresenceSync((payload) async {
          final presenceState = channel.presenceState();
          final profiles = <ProfileModel>[];

          for (final entry in presenceState) {
            final presences = entry.presences;
            for (final presence in presences) {
              final data = presence.payload;
              if (data['user_id'] != _userId) {
                try {
                  final profile = await resolveByUserId(data['user_id'] as String);
                  if (profile != null) profiles.add(profile);
                } catch (_) {}
              }
            }
          }
          onNearbyUpdated(profiles);
        })
        .subscribe((status, error) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await channel.track({
              'user_id': _userId,
              'online_at': DateTime.now().toIso8601String(),
            });
          }
        });

    return channel;
  }

  Future<ProfileModel?> resolveByUserId(String userId) async {
    final profileData = await _client
        .from(SupabaseConstants.profilesTable)
        .select('id, username, display_name, avatar_url, bio, interests, status, is_discoverable')
        .eq('id', userId)
        .eq('is_discoverable', true)
        .neq('status', 'invisible')
        .maybeSingle();

    if (profileData == null) return null;

    return ProfileModel.fromJson({
      ...profileData,
      'age': null,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
