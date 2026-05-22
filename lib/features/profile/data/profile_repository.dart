import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/profile_model.dart';
import '../../../core/constants/supabase_constants.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<ProfileModel?> getProfile(String userId) async {
    final data = await _client
        .from(SupabaseConstants.profilesTable)
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  Future<ProfileModel?> getMyProfile() async {
    return getProfile(_userId);
  }

  Future<ProfileModel> createProfile({
    required String username,
    required String displayName,
    String? bio,
    int? age,
    List<String> interests = const [],
  }) async {
    final now = DateTime.now().toIso8601String();
    final data = {
      'id': _userId,
      'username': username,
      'display_name': displayName,
      'bio': bio,
      'age': age,
      'interests': interests,
      'status': 'active',
      'is_discoverable': false,
      'created_at': now,
      'updated_at': now,
    };
    final result = await _client
        .from(SupabaseConstants.profilesTable)
        .insert(data)
        .select()
        .single();
    return ProfileModel.fromJson(result);
  }

  Future<ProfileModel> updateProfile({
    String? username,
    String? displayName,
    String? bio,
    int? age,
    List<String>? interests,
    String? status,
    bool? isDiscoverable,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (username != null) data['username'] = username;
    if (displayName != null) data['display_name'] = displayName;
    if (bio != null) data['bio'] = bio;
    if (age != null) data['age'] = age;
    if (interests != null) data['interests'] = interests;
    if (status != null) data['status'] = status;
    if (isDiscoverable != null) data['is_discoverable'] = isDiscoverable;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    final result = await _client
        .from(SupabaseConstants.profilesTable)
        .update(data)
        .eq('id', _userId)
        .select()
        .single();
    return ProfileModel.fromJson(result);
  }

  Future<String> uploadAvatar(File imageFile) async {
    final ext = imageFile.path.split('.').last;
    final filePath = '$_userId/avatar.$ext';
    await _client.storage
        .from(SupabaseConstants.avatarsBucket)
        .upload(filePath, imageFile, fileOptions: const FileOptions(upsert: true));
    final url = _client.storage
        .from(SupabaseConstants.avatarsBucket)
        .getPublicUrl(filePath);
    return url;
  }

  Future<ProfileModel?> getPublicProfile(String userId) async {
    final data = await _client
        .from(SupabaseConstants.profilesTable)
        .select('id, username, display_name, avatar_url, bio, interests, status')
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return ProfileModel.fromJson({
      ...data,
      'age': null,
      'is_discoverable': false,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> isUsernameAvailable(String username) async {
    final data = await _client
        .from(SupabaseConstants.profilesTable)
        .select('id')
        .eq('username', username)
        .neq('id', _userId)
        .maybeSingle();
    return data == null;
  }
}
