import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/conversation.dart';
import '../../worker/data/worker_providers.dart';
import '../data/chat_providers.dart';
import 'chat_time.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final me = ref.watch(currentUidProvider);
    final convsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: c.brand,
        onPressed: () => context.push('/chat/new'),
        child: const DcnIcon('edit', size: 20, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Messages', onBack: () => context.pop()),
            Expanded(
              child: convsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text('Could not load messages.',
                      style: TextStyle(color: c.textMuted)),
                ),
                data: (convs) {
                  if (convs.isEmpty || me == null) {
                    return const Center(
                      child: DcnEmptyState(
                        icon: 'msg',
                        title: 'No conversations yet',
                        body: 'Start a chat with a worker using the button below.',
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: convs.length,
                    itemBuilder: (_, i) => _ConvRow(conv: convs[i], me: me),
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

class _ConvRow extends ConsumerWidget {
  const _ConvRow({required this.conv, required this.me});
  final Conversation conv;
  final String me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final unread = conv.unreadFor(me);
    final title = conv.displayTitle(me);
    return InkWell(
      onTap: () {
        ref.read(chatRepositoryProvider).markRead(conv.id, me);
        context.push('/chat/thread/${conv.id}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            DcnAvatar(name: title, size: 50, photoUrl: conv.displayPhoto(me)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                            color: c.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        shortTime(conv.lastMessageAt),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                          color: unread ? c.brand : c.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage.isEmpty ? 'No messages yet' : conv.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: unread ? c.text : c.textMuted,
                            fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
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
