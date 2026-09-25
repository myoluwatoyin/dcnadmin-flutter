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

class ChatGroupNewScreen extends ConsumerStatefulWidget {
  const ChatGroupNewScreen({super.key});
  @override
  ConsumerState<ChatGroupNewScreen> createState() => _ChatGroupNewScreenState();
}

class _ChatGroupNewScreenState extends ConsumerState<ChatGroupNewScreen> {
  final _title = TextEditingController();
  final _selected = <String, ChatContact>{};
  String _query = '';
  bool _creating = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  bool get _valid => _title.text.trim().isNotEmpty && _selected.isNotEmpty;

  Future<void> _create() async {
    if (!_valid || _creating) return;
    final me = ref.read(currentUidProvider);
    final myInfo = ref.read(myParticipantInfoProvider);
    if (me == null || myInfo == null) return;
    setState(() => _creating = true);
    try {
      final participants = <String, ParticipantInfo>{me: myInfo};
      for (final c in _selected.values) {
        participants[c.uid] = ParticipantInfo(name: c.name, photoUrl: c.photoUrl, role: c.role);
      }
      final id = await ref.read(chatRepositoryProvider).createGroup(
            title: _title.text.trim(),
            creatorUid: me,
            participants: participants,
          );
      if (!mounted) return;
      context.pop();
      context.push('/chat/thread/$id', extra: {'title': _title.text.trim()});
    } catch (_) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not create the group. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
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
            DcnHeaderBar(
              title: 'New group',
              onBack: () => context.pop(),
              right: [
                if (_valid)
                  GestureDetector(
                    onTap: _creating ? null : _create,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: c.brand, borderRadius: BorderRadius.circular(999)),
                      child: _creating
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: DcnField(
                label: 'Group name',
                controller: _title,
                placeholder: 'e.g. Drama Leads',
                icon: 'users',
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (_selected.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final s in _selected.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: DcnChip(label: s.name, tone: DcnTone.brand),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: DcnField(
                icon: 'search',
                placeholder: 'Add workers…',
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            Expanded(
              child: contactsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(child: Text('Could not load workers.', style: TextStyle(color: c.textMuted))),
                data: (all) {
                  final list = _query.isEmpty
                      ? all
                      : all.where((w) => w.name.toLowerCase().contains(_query)).toList();
                  if (list.isEmpty) {
                    return const Center(child: DcnEmptyState(icon: 'users', title: 'No workers found'));
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final w = list[i];
                      final picked = _selected.containsKey(w.uid);
                      return InkWell(
                        onTap: () => setState(() {
                          if (picked) {
                            _selected.remove(w.uid);
                          } else {
                            _selected[w.uid] = w;
                          }
                        }),
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
                                    Text(w.name, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: c.text)),
                                    if ((w.department ?? '').isNotEmpty || (w.role ?? '').isNotEmpty)
                                      Text([w.role, w.department].where((s) => (s ?? '').isNotEmpty).join(' · '),
                                          style: TextStyle(fontSize: 12, color: c.textMuted)),
                                  ],
                                ),
                              ),
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: picked ? c.brand : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: picked ? c.brand : c.border, width: 2),
                                ),
                                child: picked ? const DcnIcon('check', size: 13, color: Colors.white) : null,
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
