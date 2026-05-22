import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/permissions/permission_manager.dart';
import '../../../../shared/models/profile_model.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../providers/nearby_provider.dart';
import '../widgets/radar_widget.dart';
import '../../../profile/providers/profile_provider.dart';

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  bool _showRadar = true;

  Future<void> _handleToggle() async {
    final nearbyState = ref.read(nearbyNotifierProvider);

    if (nearbyState.mode == NearbyMode.off) {
      // Request permissions before activating
      final permStatus = await PermissionManager.checkBleStatus();
      if (permStatus == BlePermissionStatus.permanentlyDenied) {
        if (mounted) _showPermissionDeniedDialog();
        return;
      }
      if (permStatus == BlePermissionStatus.denied) {
        final granted = await PermissionManager.requestBlePermissions();
        if (!granted && mounted) {
          context.showErrorSnack('Se necesitan permisos de Bluetooth');
          return;
        }
      }
    }

    await ref.read(nearbyNotifierProvider.notifier).toggle();
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permisos necesarios'),
        content: const Text(
          'Nearby necesita acceso a Bluetooth para descubrir personas cercanas. Ve a la configuración de tu dispositivo para activar los permisos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              PermissionManager.openSettings();
            },
            child: const Text('Abrir ajustes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nearbyState = ref.watch(nearbyNotifierProvider);
    final isActive = nearbyState.mode == NearbyMode.active;
    final users = nearbyState.nearbyUsers;
    final profileAsync = ref.watch(profileNotifierProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cerca',
                        style: AppTextStyles.headlineLarge.copyWith(color: context.textColor),
                      ),
                      Text(
                        isActive
                            ? '${users.length} ${users.length == 1 ? 'persona' : 'personas'} detectada${users.length == 1 ? '' : 's'}'
                            : 'Descubrimiento desactivado',
                        style: AppTextStyles.bodySmall.copyWith(color: context.textDimColor),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // View toggle
                      IconButton(
                        icon: Icon(
                          _showRadar ? Icons.list_rounded : Icons.radar_rounded,
                          color: context.textDimColor,
                        ),
                        onPressed: () => setState(() => _showRadar = !_showRadar),
                      ),
                      // Profile
                      profileAsync.when(
                        data: (p) => GestureDetector(
                          onTap: () => context.push('/settings'),
                          child: AppAvatar(
                            name: p?.displayName ?? '',
                            imageUrl: p?.avatarUrl,
                            size: AvatarSize.sm,
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Error banner
            if (nearbyState.error != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: AppColors.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nearbyState.error!,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),

            // Main content
            Expanded(
              child: _showRadar
                  ? _buildRadarView(isActive, users)
                  : _buildListView(isActive, users),
            ),

            // Activate button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _ActivateButton(
                isActive: isActive,
                isLoading: nearbyState.isScanning,
                onTap: _handleToggle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarView(bool isActive, List<ProfileModel> users) {
    return Column(
      children: [
        const SizedBox(height: 24),
        RadarWidget(
          isActive: isActive,
          nearbyUsers: users,
          onUserTap: (user) => context.push('/user-preview/${user.id}'),
        ),
        const SizedBox(height: 24),
        if (!isActive)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Activa el modo cerca para descubrir personas cercanas a ti',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textFaintColor,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (isActive && users.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Buscando personas cercanas...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.textFaintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (isActive && users.isNotEmpty) ...[
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _UserCard(user: users[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildListView(bool isActive, List<ProfileModel> users) {
    if (!isActive) {
      return const EmptyStateWidget(
        icon: Icons.wifi_tethering_off_rounded,
        title: 'Modo cerca desactivado',
        body: 'Activa el modo cerca para descubrir personas a tu alrededor',
      );
    }

    if (users.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.people_outline_rounded,
        title: 'Sin personas cercanas',
        body: 'No hemos detectado a nadie cerca. Asegúrate de que el Bluetooth esté activado.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _UserCard(user: users[i]),
    );
  }
}

class _ActivateButton extends StatelessWidget {
  const _ActivateButton({
    required this.isActive,
    required this.isLoading,
    required this.onTap,
  });

  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 56,
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [AppColors.danger.withOpacity(0.2), AppColors.danger.withOpacity(0.1)],
                )
              : const LinearGradient(
                  colors: [AppColors.accent, Color(0xFF9B7FFF)],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.danger.withOpacity(0.4) : Colors.transparent,
          ),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? Icons.stop_rounded : Icons.wifi_tethering_rounded,
                      color: isActive ? AppColors.danger : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isActive ? 'Desactivar modo cerca' : 'Activar modo cerca',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isActive ? AppColors.danger : Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});
  final ProfileModel user;

  String _distanceLabel(int index) {
    if (index < 2) return 'Muy cerca';
    if (index < 4) return 'Cerca';
    return 'En el área';
  }

  Color _distanceColor(String label) {
    switch (label) {
      case 'Muy cerca':
        return AppColors.success;
      case 'Cerca':
        return AppColors.warning;
      default:
        return AppColors.darkTextDim;
    }
  }

  @override
  Widget build(BuildContext context) {
    final distLabel = _distanceLabel(0);
    return GestureDetector(
      onTap: () => context.push('/user-preview/${user.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            AppAvatar(name: user.displayName, imageUrl: user.avatarUrl, size: AvatarSize.md),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: AppTextStyles.titleMedium.copyWith(color: context.textColor),
                  ),
                  if (user.interests.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.interests.take(3).join(' · '),
                      style: AppTextStyles.bodySmall.copyWith(color: context.textFaintColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _distanceColor(distLabel).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                distLabel,
                style: AppTextStyles.labelSmall.copyWith(color: _distanceColor(distLabel)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
