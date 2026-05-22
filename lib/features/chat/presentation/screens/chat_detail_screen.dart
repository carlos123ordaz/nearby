import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../data/models/message_model.dart';
import '../../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserId,
  });

  final String conversationId;
  final String otherUserName;
  final String otherUserId;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;
  final String _myId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _msgCtrl.text.trim();
    if (content.isEmpty || _isSending) return;

    _msgCtrl.clear();
    setState(() => _isSending = true);

    await ref
        .read(messagesProvider(widget.conversationId).notifier)
        .sendMessage(content);

    setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _shouldShowDate(List<MessageModel> msgs, int index) {
    if (index == 0) return true;
    final prev = msgs[index - 1].createdAt;
    final curr = msgs[index].createdAt;
    return prev.year != curr.year || prev.month != curr.month || prev.day != curr.day;
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider(widget.conversationId));

    // Auto-scroll when new messages arrive
    ref.listen(messagesProvider(widget.conversationId), (prev, next) {
      if (next.length > (prev?.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            AppAvatar(
              name: widget.otherUserName,
              size: AvatarSize.sm,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: AppTextStyles.titleMedium.copyWith(color: context.textColor),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: context.textDimColor),
            onPressed: () {},
          ),
        ],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.borderColor),
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: context.textFaintColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Di hola a ${widget.otherUserName}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.textFaintColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[i];
                      final isMe = msg.senderId == _myId;
                      final showDate = _shouldShowDate(messages, i);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: MessageBubble(
                          message: msg,
                          isMe: isMe,
                          showTimestamp: showDate,
                        ),
                      );
                    },
                  ),
          ),

          // Input
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(top: BorderSide(color: context.borderColor, width: 1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.surface2Color,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        style: AppTextStyles.bodyMedium.copyWith(color: context.textColor),
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: context.textFaintColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _msgCtrl.text.trim().isNotEmpty
                          ? AppColors.accent
                          : context.surface3Color,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: _msgCtrl.text.trim().isNotEmpty
                                  ? Colors.white
                                  : context.textFaintColor,
                              size: 18,
                            ),
                      onPressed: _msgCtrl.text.trim().isNotEmpty ? _sendMessage : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
