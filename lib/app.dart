import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

class NearbyApp extends ConsumerWidget {
  const NearbyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Nearby',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: _ConnectivityBanner(child: child!),
      ),
    );
  }
}

class _ConnectivityBanner extends ConsumerWidget {
  const _ConnectivityBanner({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityProvider);

    final isOffline       = status == ConnectivityStatus.offline;
    final justConnected   = status == ConnectivityStatus.justConnected;
    final bannerVisible   = isOffline || justConnected;

    final Color bannerColor = justConnected ? AppColors.success : const Color(0xFFB45309);
    final Color textColor   = Colors.white;
    final IconData icon     = justConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded;
    final String message    = justConnected ? 'Conexión restaurada' : 'Sin conexión a internet';

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          height: bannerVisible ? 36 : 0,
          color: bannerColor,
          child: bannerVisible
              ? SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 14, color: textColor),
                      const SizedBox(width: 6),
                      Text(
                        message,
                        style: AppTextStyles.labelMedium.copyWith(color: textColor),
                      ),
                    ],
                  ),
                )
              : null,
        ),
        Expanded(child: child),
      ],
    );
  }
}
