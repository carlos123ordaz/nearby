import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/friend_request_model.dart';
import '../../providers/friends_provider.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsNotifierProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Solicitudes',
                    style: AppTextStyles.headlineLarge.copyWith(color: context.textColor),
                  ),
                  if (state.isLoading) const LoadingWidget(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabCtrl,
              indicatorColor: AppColors.accent,
              labelColor: AppColors.accent,
              unselectedLabelColor: context.textFaintColor,
              labelStyle: AppTextStyles.titleSmall,
              unselectedLabelStyle: AppTextStyles.bodySmall,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: context.borderColor,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Recibidas'),
                      if (state.receivedRequests.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            state.receivedRequests.length.toString(),
                            style: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Enviadas'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _RequestsList(
                    requests: state.receivedRequests,
                    isReceived: true,
                    isLoading: state.isLoading,
                  ),
                  _RequestsList(
                    requests: state.sentRequests,
                    isReceived: false,
                    isLoading: state.isLoading,
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

class _RequestsList extends ConsumerWidget {
  const _RequestsList({
    required this.requests,
    required this.isReceived,
    required this.isLoading,
  });

  final List<FriendRequestModel> requests;
  final bool isReceived;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading && requests.isEmpty) {
      return const ShimmerList(count: 3);
    }

    if (requests.isEmpty) {
      return EmptyStateWidget(
        icon: isReceived ? Icons.inbox_rounded : Icons.send_rounded,
        title: isReceived ? 'Sin solicitudes pendientes' : 'Sin solicitudes enviadas',
        body: isReceived
            ? 'Cuando alguien quiera conectar contigo, aparecerá aquí'
            : 'Las solicitudes que envíes a otros usuarios aparecerán aquí',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _RequestCard(
        request: requests[i],
        isReceived: isReceived,
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request, required this.isReceived});
  final FriendRequestModel request;
  final bool isReceived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = isReceived
        ? (request.senderDisplayName ?? 'Usuario')
        : (request.receiverDisplayName ?? 'Usuario');
    final username = isReceived
        ? request.senderUsername
        : request.receiverUsername;
    final avatarUrl = isReceived
        ? request.senderAvatarUrl
        : request.receiverAvatarUrl;
    final interests = isReceived ? request.senderInterests : [];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(name: name, imageUrl: avatarUrl, size: AvatarSize.md),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.titleMedium.copyWith(color: context.textColor),
                    ),
                    if (username != null)
                      Text(
                        '@$username',
                        style: AppTextStyles.bodySmall.copyWith(color: context.textFaintColor),
                      ),
                  ],
                ),
              ),
              Text(
                request.createdAt.toTimeAgo(),
                style: AppTextStyles.labelSmall.copyWith(color: context.textFaintColor),
              ),
            ],
          ),
          if (interests.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: interests.take(4).map((i) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.surface2Color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(i, style: AppTextStyles.labelSmall.copyWith(color: context.textFaintColor)),
                );
              }).toList(),
            ),
          ],
          if (isReceived) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(friendsNotifierProvider.notifier).rejectRequest(request.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textDimColor,
                      side: BorderSide(color: context.borderStrongColor),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref.read(friendsNotifierProvider.notifier).acceptRequest(request.id),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => ref.read(friendsNotifierProvider.notifier)
                    .cancelRequest(request.receiverId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(color: AppColors.danger.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Cancelar solicitud'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
