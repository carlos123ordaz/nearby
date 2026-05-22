import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/profile_model.dart';
import '../data/profile_repository.dart';
import '../../auth/providers/auth_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final myProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  return ref.watch(profileRepositoryProvider).getMyProfile();
});

final profileByIdProvider = FutureProvider.family<ProfileModel?, String>((ref, userId) async {
  return ref.watch(profileRepositoryProvider).getPublicProfile(userId);
});

class ProfileNotifier extends StateNotifier<AsyncValue<ProfileModel?>> {
  final ProfileRepository _repo;
  final Ref _ref;

  ProfileNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await _repo.getMyProfile();
      state = AsyncValue.data(profile);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> refresh() => _load();

  Future<void> createProfile({
    required String username,
    required String displayName,
    String? avatarUrl,
    String? bio,
    int? age,
    List<String> interests = const [],
  }) async {
    final profile = await _repo.createProfile(
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      bio: bio,
      age: age,
      interests: interests,
    );
    state = AsyncValue.data(profile);
    // Invalidate so the router re-checks and allows navigation to /main.
    _ref.invalidate(hasProfileProvider);
  }

  // Only uploads the file to storage — does NOT update the profile row.
  // Use this before createProfile so the URL can be included in the insert.
  Future<String?> uploadAvatarFile(File imageFile) async {
    try {
      return await _repo.uploadAvatar(imageFile);
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateProfile({
    String? username,
    String? displayName,
    String? bio,
    int? age,
    List<String>? interests,
    String? status,
    bool? isDiscoverable,
    String? avatarUrl,
  }) async {
    try {
      final profile = await _repo.updateProfile(
        username: username,
        displayName: displayName,
        bio: bio,
        age: age,
        interests: interests,
        status: status,
        isDiscoverable: isDiscoverable,
        avatarUrl: avatarUrl,
      );
      state = AsyncValue.data(profile);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final url = await _repo.uploadAvatar(imageFile);
      await updateProfile(avatarUrl: url);
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<bool> setDiscoverable(bool value) async {
    return updateProfile(isDiscoverable: value, status: value ? 'active' : 'inactive');
  }
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileModel?>>((ref) {
  return ProfileNotifier(ref.watch(profileRepositoryProvider), ref);
});
