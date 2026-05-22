import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../friends/providers/friends_provider.dart';
import '../../../friends/data/models/friend_request_model.dart';

class UserPreviewScreen extends ConsumerWidget {
  const UserPreviewScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(userId));
    final myProfileAsync = ref.watch(profileNotifierProvider);
    final myId = myProfileAsync.value?.id;

    final requestState = ref.watch(friendRequestStateProvider(userId));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showOptions(context, ref),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(
                'Usuario no encontrado',
                style: AppTextStyles.bodyMedium.copyWith(color: context.textDimColor),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar and name
                Center(
                  child: Column(
                    children: [
                      AppAvatar(
                        name: profile.displayName,
                        imageUrl: profile.avatarUrl,
                        size: AvatarSize.xl,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.displayName,
                        style: AppTextStyles.headlineLarge.copyWith(color: context.textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${profile.username}',
                        style: AppTextStyles.bodyMedium.copyWith(color: context.textDimColor),
                      ),
                      const SizedBox(height: 8),
                      // Distance badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.successSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.radio_button_on_rounded, color: AppColors.success, size: 10),
                            const SizedBox(width: 6),
                            Text(
                              'Muy cerca',
                              style: AppTextStyles.labelMedium.copyWith(color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Bio
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  _Section(
                    title: 'Bio',
                    child: Text(
                      profile.bio!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.textDimColor,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Interests
                if (profile.interests.isNotEmpty) ...[
                  _Section(
                    title: 'Intereses',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.interests.map((i) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.surface2Color,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Text(
                            i,
                            style: AppTextStyles.labelMedium.copyWith(color: context.textDimColor),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Actions
                if (myId != userId) ...[
                  requestState.when(
                    loading: () => const LoadingWidget(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (status) => _buildActionButton(context, ref, status),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    FriendRequestStatus? status,
  ) {
    if (status == FriendRequestStatus.accepted) {
      return AppButton(
        label: 'Amigos',
        variant: AppButtonVariant.secondary,
        icon: Icons.check_rounded,
        onPressed: null,
      );
    }

    if (status == FriendRequestStatus.pending) {
      return Column(
        children: [
          AppButton(
            label: 'Solicitud enviada',
            variant: AppButtonVariant.secondary,
            onPressed: null,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Cancelar solicitud',
            variant: AppButtonVariant.ghost,
            onPressed: () async {
              await ref.read(friendsNotifierProvider.notifier).cancelRequest(userId);
            },
          ),
        ],
      );
    }

    return AppButton(
      label: 'Enviar solicitud de amistad',
      icon: Icons.person_add_rounded,
      onPressed: () async {
        final success = await ref.read(friendsNotifierProvider.notifier).sendRequest(userId);
        if (context.mounted) {
          if (success) {
            context.showSuccessSnack('Solicitud enviada');
          } else {
            context.showErrorSnack('Error al enviar solicitud');
          }
        }
      },
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderStrongColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: AppColors.danger),
              title: Text(
                'Bloquear usuario',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(friendsNotifierProvider.notifier).blockUser(userId);
                if (context.mounted) {
                  context.showSuccessSnack('Usuario bloqueado');
                  context.pop();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_rounded, color: AppColors.warning),
              title: Text(
                'Reportar usuario',
                style: AppTextStyles.bodyMedium.copyWith(color: context.textColor),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showReportDialog(context, ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, WidgetRef ref) {
    final reasons = ['Comportamiento inapropiado', 'Contenido ofensivo', 'Spam', 'Otro'];
    String? selectedReason;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Reportar usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons
                .map((r) => RadioListTile<String>(
                      title: Text(r),
                      value: r,
                      groupValue: selectedReason,
                      onChanged: (v) => setState(() => selectedReason = v),
                      activeColor: AppColors.accent,
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await ref.read(friendsNotifierProvider.notifier).reportUser(
                            userId,
                            reason: selectedReason!,
                          );
                      if (context.mounted) context.showSuccessSnack('Reporte enviado');
                    },
              child: const Text('Reportar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(color: context.textColor),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
