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

class ChatNewScreen extends ConsumerStatefulWidget {
  const ChatNewScreen({super.key});
  @override
  ConsumerState<ChatNewScreen> createState() => _ChatNewScreenState();
}

class _ChatNewScreenState extends ConsumerState<ChatNewScreen> {
  String _query = '';
  bool _opening = false;

  Future<void> _open(ChatContact contact) async {
    if (_opening) return;
    final me = ref.read(currentUidProvider);
    final myInfo = ref.read(myParticipantInfoProvider);
    if (me == null || myInfo == null) return;
    setState(() => _opening = true);
    try {
      final id = await ref.read(chatRepositoryProvider).openDirect(
            me: me,
            meInfo: myInfo,
            other: contact.uid,
            otherInfo: ParticipantInfo(
              name: contact.name,
              photoUrl: contact.photoUrl,
              role: contact.role,
            ),
          );
      if (!mounted) return;
      context.pop(); // close picker
      context.push('/chat/thread/$id', extra: {'title': contact.name});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open the chat. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final contactsAsync = ref.watch(chatContactsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'New message', onBack: () => context.pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: DcnField(
                icon: 'search',
                placeholder: 'Search workers…',
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            InkWell(
              onTap: () => context.push('/chat/group/new'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
                      child: DcnIcon('users', size: 20, color: c.brand),
                    ),
                    const SizedBox(width: 12),
                    Text('New group',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: c.brand)),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: c.divider),
            Expanded(
              child: contactsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text('Could not load workers.', style: TextStyle(color: c.textMuted)),
                ),
                data: (all) {
                  final list = _query.isEmpty
                      ? all
                      : all.where((w) => w.name.toLowerCase().contains(_query)).toList();
                  if (list.isEmpty) {
                    return const Center(
                      child: DcnEmptyState(icon: 'users', title: 'No workers found'),
                    );
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final w = list[i];
                      return InkWell(
                        onTap: () => _open(w),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              DcnAvatar(name: w.name, size: 44, photoUrl: w.photoUrl),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(w.name,
                                        style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: c.text)),
                                    if ((w.department ?? '').isNotEmpty || (w.role ?? '').isNotEmpty)
                                      Text(
                                        [w.role, w.department].where((s) => (s ?? '').isNotEmpty).join(' · '),
                                        style: TextStyle(fontSize: 12, color: c.textMuted),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
