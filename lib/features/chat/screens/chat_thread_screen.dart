import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage_service.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../models/chat_message.dart';
import '../../worker/data/worker_providers.dart';
import '../data/chat_providers.dart';
import 'chat_time.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({super.key, required this.convId, this.title});
  final String convId;
  final String? title;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final me = ref.read(currentUidProvider);
    if (me != null) ref.read(chatRepositoryProvider).markRead(widget.convId, me);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final me = ref.read(currentUidProvider);
    final myInfo = ref.read(myParticipantInfoProvider);
    if (me == null || myInfo == null) return;
    _input.clear();
    setState(() => _sending = true);
    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            widget.convId,
            senderUid: me,
            senderName: myInfo.name,
            text: text,
          );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImage() async {
    final me = ref.read(currentUidProvider);
    final myInfo = ref.read(myParticipantInfoProvider);
    if (me == null || myInfo == null) return;
    final path = await ref.read(storageServiceProvider).pickImage();
    if (path == null) return;
    setState(() => _sending = true);
    try {
      final name = 'chat_${widget.convId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await ref.read(storageServiceProvider).uploadAttachment(me, name, path, contentType: 'image/jpeg');
      await ref.read(chatRepositoryProvider).sendMessage(
            widget.convId,
            senderUid: me,
            senderName: myInfo.name,
            imageUrl: url,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not send image.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final me = ref.watch(currentUidProvider);
    final msgsAsync = ref.watch(messagesProvider(widget.convId));
    final conv = ref.watch(conversationProvider(widget.convId)).valueOrNull;
    final isGroup = conv?.isGroup ?? false;
    final headerTitle = (me != null ? conv?.displayTitle(me) : null) ?? widget.title ?? 'Chat';
    final headerSub = isGroup ? '${conv!.participantUids.length} members' : null;

    // Mark read + scroll to bottom whenever new messages arrive.
    ref.listen(messagesProvider(widget.convId), (_, next) {
      final list = next.valueOrNull;
      if (list != null && list.isNotEmpty) {
        if (me != null) ref.read(chatRepositoryProvider).markRead(widget.convId, me);
        _scrollToEnd();
      }
    });

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: headerTitle, sub: headerSub, onBack: () => context.pop()),
            Expanded(
              child: msgsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text('Could not load messages.', style: TextStyle(color: c.textMuted)),
                ),
                data: (msgs) {
                  if (msgs.isEmpty) {
                    return Center(
                      child: Text('Say hello 👋',
                          style: TextStyle(color: c.textMuted, fontSize: 14)),
                    );
                  }
                  _scrollToEnd();
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final msg = msgs[i];
                      final mine = me != null && msg.isMine(me);
                      final showDay = i == 0 || !_sameDay(msgs[i - 1].createdAt, msg.createdAt);
                      // Show the sender's name above inbound group messages when
                      // the previous message was from someone else.
                      final showSender = isGroup && !mine &&
                          (i == 0 || msgs[i - 1].senderUid != msg.senderUid);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDay) _DaySeparator(date: msg.createdAt),
                          _Bubble(msg: msg, mine: mine, showSender: showSender),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _Composer(
              controller: _input,
              sending: _sending,
              onSend: _send,
              onImage: _sendImage,
            ),
          ],
        ),
      ),
    );
  }
}

bool _sameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return a == b;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.date});
  final DateTime? date;

  String _label() {
    if (date == null) return '';
    final now = DateTime.now();
    final d = DateTime(date!.year, date!.month, date!.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date!.day} ${months[date!.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(999)),
        child: Text(_label(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textMuted)),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg, required this.mine, this.showSender = false});
  final ChatMessage msg;
  final bool mine;
  final bool showSender;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final bg = mine ? c.brand : c.surface2;
    final fg = mine ? Colors.white : c.text;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSender)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  msg.senderName,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c.brand),
                ),
              ),
            if (msg.hasImage)
              Padding(
                padding: EdgeInsets.only(bottom: msg.text.isNotEmpty ? 6 : 2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(msg.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                ),
              ),
            if (msg.text.isNotEmpty)
              Text(msg.text, style: TextStyle(fontSize: 14.5, color: fg, height: 1.25)),
            const SizedBox(height: 3),
            Text(
              clockTime(msg.createdAt),
              style: TextStyle(
                fontSize: 9.5,
                color: mine ? Colors.white70 : c.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onImage,
  });
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onImage;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: sending ? null : onImage,
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
                child: DcnIcon('camera', size: 20, color: c.brand),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: c.text, fontSize: 14.5),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Message…',
                    hintStyle: TextStyle(color: c.textMuted),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: sending ? null : onSend,
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
                child: sending
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const DcnIcon('send', size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
