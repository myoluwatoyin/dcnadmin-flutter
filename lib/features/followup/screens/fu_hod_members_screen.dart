import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/member.dart';
import '../data/fu_hod_providers.dart';
import '../widgets/fu_widgets.dart';

const _filters = [
  (id: 'ALL', label: 'All'),
  (id: 'ACTIVE', label: 'Active'),
  (id: 'AT_RISK', label: 'At risk'),
  (id: 'FIRST', label: 'First-timers'),
  (id: 'UNREACH', label: 'Unreachable'),
];

/// The FU HOD's church-wide member directory.
class FuHodMembersScreen extends ConsumerStatefulWidget {
  const FuHodMembersScreen({super.key});
  @override
  ConsumerState<FuHodMembersScreen> createState() => _State();
}

class _State extends ConsumerState<FuHodMembersScreen> {
  String _filter = 'ALL';
  String _q = '';

  bool _match(Member m) {
    if (_filter == 'ACTIVE' && m.status != 'Active') return false;
    if (_filter == 'AT_RISK' && !m.isAtRisk) return false;
    if (_filter == 'FIRST' && !m.isFirstTimer) return false;
    if (_filter == 'UNREACH' && !m.unreachable) return false;
    if (_q.isNotEmpty && !m.name.toLowerCase().contains(_q.toLowerCase())) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final membersA = ref.watch(allMembersProvider);
    final members = membersA.valueOrNull ?? const <Member>[];
    final atRisk = members.where((m) => m.isAtRisk).length;
    final filtered = members.where(_match).toList();

    return Column(
      children: [
        DcnHeaderBar(
          title: 'All members',
          sub: '${members.length} tracked · $atRisk at risk',
          right: [
            GestureDetector(
              onTap: () => context.push('/fu/add-member'),
              child: Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle), child: const DcnIcon('plus', size: 20, color: Colors.white)),
            ),
          ],
        ),
        Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              DcnField(icon: 'search', placeholder: 'Search by name…', onChanged: (v) => setState(() => _q = v)),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final f in _filters)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = f.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: _filter == f.id ? c.brand : c.surface2, borderRadius: BorderRadius.circular(999)),
                            child: Text(f.label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _filter == f.id ? Colors.white : c.textMuted)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: membersA.isLoading && !membersA.hasValue
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const DcnEmptyState(icon: 'users', title: 'No members', body: 'No one matches this filter.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => MemberRow(member: filtered[i], onTap: () => context.push('/fu/member/${filtered[i].id}')),
                    ),
        ),
      ],
    );
  }
}

// ── Absence queue ────────────────────────────────────────────
class FuHodAbsenceScreen extends ConsumerWidget {
  const FuHodAbsenceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final queue = ref.watch(absenceQueueProvider);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Absence escalation', sub: '${queue.length} members triggered automation', onBack: () => context.pop()),
            Expanded(
              child: queue.isEmpty
                  ? const DcnEmptyState(icon: 'checkCircle', title: 'Nobody flagged', body: 'No members are past the absence threshold.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: queue.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final m = queue[i];
                        final tone = m.unreachable ? DcnTone.danger : DcnTone.warning;
                        return DcnCard(
                          onTap: () => context.push('/fu/member/${m.id}'),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  DcnAvatar(name: m.name, size: 40),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(m.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                                        Text('${m.weeksAbsent} weeks absent · last ${m.lastAttended}', style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                                      ],
                                    ),
                                  ),
                                  DcnChip(label: m.unreachable ? 'Unreachable' : 'At risk', tone: tone, size: DcnButtonSize.sm),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(children: [
                                DcnButton(label: 'Reassign', variant: DcnButtonVariant.ghost, size: DcnButtonSize.sm, icon: 'users', onPressed: () => context.push('/fh/assign?member=${m.id}')),
                                const SizedBox(width: 8),
                                DcnButton(
                                  label: 'Pastoral visit',
                                  variant: DcnButtonVariant.ghost,
                                  size: DcnButtonSize.sm,
                                  icon: 'alert',
                                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked for pastoral visit'), behavior: SnackBarBehavior.floating)),
                                ),
                              ]),
                            ],
                          ),
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

// ── Unreachable ──────────────────────────────────────────────
class FuHodUnreachableScreen extends ConsumerWidget {
  const FuHodUnreachableScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final items = ref.watch(unreachableMembersProvider);
    final cumulative = items.fold<int>(0, (s, m) => s + m.weeksAbsent);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Unreachable members', sub: '${items.length} members · ${cumulative}w cumulative absence', onBack: () => context.pop()),
            Expanded(
              child: items.isEmpty
                  ? const DcnEmptyState(icon: 'checkCircle', title: 'None unreachable', body: 'Every member has been reached recently.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final m = items[i];
                        return DcnCard(
                          onTap: () => context.push('/fu/member/${m.id}'),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              DcnAvatar(name: m.name, size: 44),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                                    Text('${m.weeksAbsent}w absent · last ${m.lastAttended}', style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                                  ],
                                ),
                              ),
                              const DcnChip(label: 'Unreachable', tone: DcnTone.danger, size: DcnButtonSize.sm, icon: 'alert'),
                            ],
                          ),
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
