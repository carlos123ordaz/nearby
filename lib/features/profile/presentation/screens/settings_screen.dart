import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../providers/profile_provider.dart';
import '../../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: context.bgColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          // Profile header
          profileAsync.when(
            data: (profile) => profile != null
                ? ListTile(
                    leading: AppAvatar(
                      imageUrl: profile.avatarUrl,
                      name: profile.displayName,
                      size: AvatarSize.md,
                    ),
                    title: Text(
                      profile.displayName,
                      style: AppTextStyles.titleMedium.copyWith(color: context.textColor),
                    ),
                    subtitle: Text(
                      '@${profile.username}',
                      style: AppTextStyles.bodySmall.copyWith(color: context.textDimColor),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () => context.push('/edit-profile'),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Divider(color: context.borderColor, height: 1),
          const SizedBox(height: 8),

          _SectionTitle('Apariencia'),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            title: 'Tema oscuro',
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (v) {
                ref.read(themeModeProvider.notifier).state =
                    v ? ThemeMode.dark : ThemeMode.light;
              },
            ),
          ),

          const SizedBox(height: 8),
          _SectionTitle('Privacidad'),
          _SettingsTile(
            icon: Icons.visibility_rounded,
            title: 'Modo invisible',
            subtitle: 'No aparecerás en búsquedas cercanas',
            trailing: Switch(
              value: profileAsync.value?.status == 'invisible',
              onChanged: (v) async {
                final notifier = ref.read(profileNotifierProvider.notifier);
                await notifier.updateProfile(status: v ? 'invisible' : 'active');
              },
            ),
          ),
          _SettingsTile(
            icon: Icons.bluetooth_disabled_rounded,
            title: 'Desactivar descubrimiento',
            subtitle: 'Otros no podrán detectarte',
            trailing: Switch(
              value: profileAsync.value?.isDiscoverable == false,
              onChanged: (v) async {
                final notifier = ref.read(profileNotifierProvider.notifier);
                await notifier.setDiscoverable(!v);
              },
            ),
          ),

          const SizedBox(height: 8),
          _SectionTitle('Cuenta'),
          _SettingsTile(
            icon: Icons.lock_rounded,
            title: 'Cambiar contraseña',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Acerca de Nearby',
            onTap: () => _showAboutDialog(context),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_rounded,
            title: 'Política de privacidad',
            onTap: () {},
          ),

          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Cerrar sesión',
            iconColor: AppColors.danger,
            titleColor: AppColors.danger,
            onTap: () => _confirmSignOut(context, ref),
          ),
          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            title: 'Eliminar cuenta',
            subtitle: 'Esta acción no se puede deshacer',
            iconColor: AppColors.danger,
            titleColor: AppColors.danger,
            onTap: () {},
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/welcome');
            },
            child: Text('Cerrar sesión', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Nearby',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 Nearby App',
      children: [
        const SizedBox(height: 12),
        const Text('Descubre personas cercanas usando Bluetooth Low Energy de forma privada y segura.'),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: context.textFaintColor,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? context.textDimColor, size: 22),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: titleColor ?? context.textColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(color: context.textFaintColor),
            )
          : null,
      trailing: trailing ?? (onTap != null ? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.textFaintColor) : null),
      onTap: onTap,
    );
  }
}
