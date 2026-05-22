import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => Supabase.instance.client.auth.currentUser,
    error: (_, __) => null,
  );
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signIn(email: email, password: password);
      state = const AsyncValue.data(null);
      return true;
    } on AuthException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error('Error inesperado', StackTrace.current);
      return false;
    }
  }

  Future<bool> signUp({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signUp(email: email, password: password);
      state = const AsyncValue.data(null);
      return true;
    } on AuthException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error('Error inesperado', StackTrace.current);
      return false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncValue.data(null);
  }

  Future<bool> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repo.resetPassword(email);
      state = const AsyncValue.data(null);
      return true;
    } on AuthException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error('Error inesperado', StackTrace.current);
      return false;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _repo.signInWithGoogle();
      // Navigation is handled by the auth state stream after the OAuth redirect
      state = const AsyncValue.data(null);
    } on AuthException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
    } catch (e) {
      state = AsyncValue.error('Error al iniciar con Google', StackTrace.current);
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

// True when the current user has a row in the profiles table.
// The router uses this to redirect new OAuth users to complete-profile.
final hasProfileProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  final row = await Supabase.instance.client
      .from('profiles')
      .select('id')
      .eq('id', user.id)
      .maybeSingle();
  return row != null;
});
