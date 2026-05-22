import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/conversation_model.dart';
import '../../providers/chat_provider.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatNotifierProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mensajes',
                    style: AppTextStyles.headlineLarge.copyWith(color: context.textColor),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: context.textFaintColor),
                    onPressed: () => ref.read(chatNotifierProvider.notifier).loadConversations(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: chatState.when(
                loading: () => const ShimmerList(count: 5),
                error: (e, _) => Center(
                  child: Text('Error: $e', style: AppTextStyles.bodyMedium),
                ),
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Sin conversaciones',
                      body: 'Acepta solicitudes de amistad para poder chatear con otras personas',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) => Divider(
                      color: context.borderColor,
                      height: 1,
                      indent: 72,
                    ),
                    itemBuilder: (_, i) => _ConversationTile(conv: conversations[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conv});
  final ConversationModel conv;

  @override
  Widget build(BuildContext context) {
    final profile = conv.otherProfile;
    final lastMsg = conv.lastMessage;
    final hasUnread = conv.unreadCount > 0;

    return GestureDetector(
      onTap: () => context.push(
        '/chat/${conv.id}',
        extra: {
          'otherUserName': profile?.displayName ?? '',
          'otherUserId': profile?.id ?? '',
        },
      ),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            AppAvatar(
              name: profile?.displayName ?? '',
              imageUrl: profile?.avatarUrl,
              size: AvatarSize.md,
              showOnline: true,
              isOnline: profile?.status == 'active',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        profile?.displayName ?? 'Usuario',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: context.textColor,
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      if (lastMsg != null)
                        Text(
                          lastMsg.createdAt.isToday
                              ? lastMsg.createdAt.toFormattedTime()
                              : lastMsg.createdAt.toFormattedDate(),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: hasUnread ? AppColors.accent : context.textFaintColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg?.content ?? 'Comenzar conversación',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: hasUnread ? context.textDimColor : context.textFaintColor,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            conv.unreadCount.toString(),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
