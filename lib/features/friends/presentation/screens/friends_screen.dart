import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/friendship_model.dart';
import '../../providers/friends_provider.dart';
import '../../../chat/providers/chat_provider.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsNotifierProvider);
    final filtered = state.friends
        .where((f) =>
            _query.isEmpty ||
            (f.friendProfile?.displayName.toLowerCase().contains(_query.toLowerCase()) ?? false))
        .toList();

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amigos',
                        style: AppTextStyles.headlineLarge.copyWith(color: context.textColor),
                      ),
                      Text(
                        '${state.friends.length} amigos',
                        style: AppTextStyles.labelMedium.copyWith(color: context.textFaintColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar amigos...',
                      prefixIcon: Icon(Icons.search_rounded, color: context.textFaintColor, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, color: context.textFaintColor, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.isLoading && state.friends.isEmpty
                  ? const ShimmerList()
                  : RefreshIndicator(
                      onRefresh: () => ref.read(friendsNotifierProvider.notifier).loadAll(),
                      color: AppColors.accent,
                      child: filtered.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.5,
                                  child: EmptyStateWidget(
                                    icon: Icons.people_outline_rounded,
                                    title: _query.isNotEmpty ? 'Sin resultados' : 'Sin amigos aún',
                                    body: _query.isNotEmpty
                                        ? 'No encontramos a nadie con ese nombre'
                                        : 'Activa el modo cerca para descubrir personas y enviar solicitudes',
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) => _FriendCard(friendship: filtered[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendCard extends ConsumerWidget {
  const _FriendCard({required this.friendship});
  final FriendshipModel friendship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = friendship.friendProfile;
    if (profile == null) return const SizedBox.shrink();

    final isOnline = profile.status == 'active';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          AppAvatar(
            name: profile.displayName,
            imageUrl: profile.avatarUrl,
            size: AvatarSize.md,
            showOnline: true,
            isOnline: isOnline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: AppTextStyles.titleMedium.copyWith(color: context.textColor),
                ),
                Text(
                  '@${profile.username}',
                  style: AppTextStyles.bodySmall.copyWith(color: context.textFaintColor),
                ),
                if (profile.interests.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    profile.interests.take(3).join(' · '),
                    style: AppTextStyles.labelSmall.copyWith(color: context.textFaintColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Chat button
              IconButton(
                icon: Icon(Icons.chat_bubble_rounded, color: AppColors.accent, size: 20),
                onPressed: () async {
                  final chatNotifier = ref.read(chatNotifierProvider.notifier);
                  final convId = await chatNotifier.getOrCreateConversation(profile.id);
                  if (context.mounted && convId != null) {
                    context.push('/chat/$convId', extra: {
                      'otherUserName': profile.displayName,
                      'otherUserId': profile.id,
                    });
                  }
                },
              ),
              // More options
              IconButton(
                icon: Icon(Icons.more_vert_rounded, color: context.textFaintColor, size: 20),
                onPressed: () => _showOptions(context, ref, profile.id, profile.displayName),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref, String friendId, String name) {
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
            const SizedBox(height: 8),
            ListTile(
              title: Text(name, style: AppTextStyles.titleMedium.copyWith(color: context.textColor)),
              subtitle: Text('Amigo', style: AppTextStyles.bodySmall.copyWith(color: context.textFaintColor)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.person_remove_rounded, color: context.textDimColor),
              title: Text('Eliminar amigo', style: AppTextStyles.bodyMedium.copyWith(color: context.textColor)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmRemove(context, ref, friendId, name);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: AppColors.danger),
              title: Text('Bloquear', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(friendsNotifierProvider.notifier).blockUser(friendId);
                if (context.mounted) context.showSuccessSnack('Usuario bloqueado');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref, String friendId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar amigo'),
        content: Text('¿Seguro que quieres eliminar a $name de tus amigos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(friendsNotifierProvider.notifier).removeFriend(friendId);
            },
            child: Text('Eliminar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
