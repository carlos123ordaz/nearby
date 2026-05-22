import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/profile/presentation/screens/complete_profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/nearby/presentation/screens/user_preview_screen.dart';
import '../../features/chat/presentation/screens/chat_detail_screen.dart';
import '../../features/main/main_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

// Pages that unauthenticated users can visit.
const _guestOnlyRoutes = {
  '/',
  '/welcome',
  '/login',
  '/register',
  '/forgot-password',
};

// Listens to auth + profile state and notifies GoRouter to re-run redirect.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, __) => notifyListeners());
    _ref.listen<AsyncValue<bool>>(hasProfileProvider,    (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync = _ref.read(authStateProvider);
    if (authAsync.isLoading) return null;

    final isLoggedIn = authAsync.valueOrNull?.session != null;
    final loc = state.matchedLocation;

    // Not logged in → only guest pages are allowed.
    if (!isLoggedIn) {
      return _guestOnlyRoutes.contains(loc) ? null : '/welcome';
    }

    // Logged in → check whether a profile row exists.
    final profileAsync = _ref.read(hasProfileProvider);
    if (profileAsync.isLoading) return null; // wait for the check

    final hasProfile = profileAsync.valueOrNull ?? false;

    if (!hasProfile) {
      // New OAuth user with no profile yet → must complete it.
      return loc == '/complete-profile' ? null : '/complete-profile';
    }

    // Profile exists → don't let them linger on guest or setup pages.
    if (_guestOnlyRoutes.contains(loc) || loc == '/complete-profile') return '/main';

    return null;
  }
}

final _routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  // ref.read so the GoRouter instance is created only once.
  final notifier = ref.read(_routerNotifierProvider);

  // Keep the notifier alive as long as the router lives.
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/user-preview/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserPreviewScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ChatDetailScreen(
            conversationId: conversationId,
            otherUserName: extra?['otherUserName'] ?? '',
            otherUserId: extra?['otherUserId'] ?? '',
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Página no encontrada: ${state.error}')),
    ),
  );
});
