import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_sheet.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/application.dart';
import '../../../models/member.dart';
import '../../../models/team_worker.dart';
import '../../followup/data/fu_hod_providers.dart';
import '../../followup/widgets/fu_widgets.dart';
import '../data/pastor_providers.dart';

class PastorPeopleScreen extends ConsumerStatefulWidget {
  const PastorPeopleScreen({super.key});
  @override
  ConsumerState<PastorPeopleScreen> createState() => _State();
}

class _State extends ConsumerState<PastorPeopleScreen> {
  String _tab = 'workers';
  String _q = '';
  String _dept = 'ALL';

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final stats = ref.watch(pastorStatsProvider);
    final apps = ref.watch(pastorApplicationsProvider).valueOrNull ?? const [];

    return Column(
      children: [
        DcnHeaderBar(title: 'People', sub: '${stats.members} members · ${stats.workers} workers'),
        Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: DcnSegmented(
            options: [
              (id: 'workers', label: 'Workers'),
              (id: 'members', label: 'Members'),
              (id: 'approvals', label: 'Pending (${apps.length})'),
            ],
            value: _tab,
            onChanged: (v) => setState(() => _tab = v),
          ),
        ),
        Expanded(child: switch (_tab) {
          'workers' => _workers(c),
          'members' => _members(c),
          _ => _approvals(c),
        }),
      ],
    );
  }

  Widget _workers(DcnColors c) {
    final workers = ref.watch(pastorWorkersProvider);
    final depts = ['ALL', 'Worship', 'Media', 'Ushering', 'Drama', 'Technical', 'Follow-Up'];
    final filtered = workers.where((w) {
      if (_dept != 'ALL' && w.departmentName != _dept) return false;
      if (_q.isNotEmpty && !w.name.toLowerCase().contains(_q.toLowerCase())) return false;
      return true;
    }).toList();

    return Column(
      children: [
        Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            children: [
              DcnField(icon: 'search', placeholder: 'Search workers…', onChanged: (v) => setState(() => _q = v)),
              const SizedBox(height: 10),
              SizedBox(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final d in depts)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _dept = d),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: _dept == d ? c.brand : c.surface2, borderRadius: BorderRadius.circular(999)),
                            child: Text(d == 'ALL' ? 'All depts' : d, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _dept == d ? Colors.white : c.textMuted)),
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
          child: filtered.isEmpty
              ? const DcnEmptyState(icon: 'users', title: 'No workers', body: 'No one matches this filter.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _WorkerRow(w: filtered[i], onTap: () => context.push('/p/worker/${filtered[i].uid}')),
                ),
        ),
      ],
    );
  }

  Widget _members(DcnColors c) {
    final members = ref.watch(allMembersProvider).valueOrNull ?? const <Member>[];
    final filtered = members.where((m) => _q.isEmpty || m.name.toLowerCase().contains(_q.toLowerCase())).toList();
    return Column(
      children: [
        Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: DcnField(icon: 'search', placeholder: 'Search members…', onChanged: (v) => setState(() => _q = v)),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const DcnEmptyState(icon: 'users', title: 'No members', body: 'No one matches.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => MemberRow(member: filtered[i], onTap: () => context.push('/fu/member/${filtered[i].id}')),
                ),
        ),
      ],
    );
  }

  Widget _approvals(DcnColors c) {
    final apps = ref.watch(pastorApplicationsProvider).valueOrNull ?? const <Application>[];
    return apps.isEmpty
        ? const DcnEmptyState(icon: 'checkCircle', title: 'All caught up', body: 'No new sign-ups across any dept.')
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: apps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _ApprovalCard(a: apps[i], onDecide: _decide),
          );
  }

  Future<void> _decide(Application a, bool approved) async {
    String? reason;
    if (!approved) {
      reason = await _rejectReason();
      if (reason == null) return;
    }
    try {
      await ref.read(hodDecideProvider)(a.id, approved, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approved ? 'Approved · welcome SMS sent' : 'Application declined'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<String?> _rejectReason() {
    final ctrl = TextEditingController();
    return showDcnSheet<String>(
      context: context,
      title: 'Decline application',
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A reason is required. The applicant is notified.', style: TextStyle(fontSize: 13, color: ctx.dcn.textMuted)),
          const SizedBox(height: 12),
          DcnField(label: 'Reason', controller: ctrl, multiline: true),
          const SizedBox(height: 14),
          DcnButton(label: 'Decline', variant: DcnButtonVariant.danger, icon: 'x', full: true, onPressed: () => ctrl.text.trim().isEmpty ? null : Navigator.of(ctx).pop(ctrl.text)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Standalone church-wide approvals screen (deep-linked from Home / More).
class PastorApprovalsScreen extends ConsumerWidget {
  const PastorApprovalsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final apps = ref.watch(pastorApplicationsProvider).valueOrNull ?? const <Application>[];

    Future<void> decide(Application a, bool approved) async {
      try {
        await ref.read(hodDecideProvider)(a.id, approved);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(approved ? 'Approved · welcome SMS sent' : 'Application declined'),
            behavior: SnackBarBehavior.floating,
          ));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$e'),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Approvals', sub: '${apps.length} across all departments', onBack: () => context.pop()),
            Expanded(
              child: apps.isEmpty
                  ? const DcnEmptyState(icon: 'checkCircle', title: 'All caught up', body: 'No new sign-ups across any dept.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: apps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ApprovalCard(a: apps[i], onDecide: decide),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Decide provider bridges to the Pastor repo's decideApplication Cloud Function
// (Pastor passes the manages() rule for any department).
final hodDecideProvider = Provider((ref) {
  final repo = ref.read(pastorRepositoryProvider);
  return (String id, bool approved, {String? reason}) async {
    await repo.decideApplication(id, approved: approved, reason: reason);
  };
});

class _WorkerRow extends StatelessWidget {
  const _WorkerRow({required this.w, required this.onTap});
  final TeamWorker w;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return DcnCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          DcnAvatar(name: w.name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(w.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text))),
                  if (w.isHod) ...[const SizedBox(width: 6), const DcnChip(label: 'HOD', tone: DcnTone.brand, size: DcnButtonSize.sm)] else if (w.isSubHod) ...[const SizedBox(width: 6), const DcnChip(label: 'Sub-HOD', tone: DcnTone.info, size: DcnButtonSize.sm)],
                  if (w.isSuspended) ...[const SizedBox(width: 6), const DcnChip(label: 'Suspended', tone: DcnTone.danger, size: DcnButtonSize.sm, icon: 'lock')],
                ]),
                const SizedBox(height: 2),
                Text([w.departmentName, w.subUnit].where((s) => s.isNotEmpty).join(' · '), style: TextStyle(fontSize: 12, color: c.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.a, required this.onDecide});
  final Application a;
  final Future<void> Function(Application, bool) onDecide;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return DcnCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DcnAvatar(name: a.name, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(child: Text(a.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text))),
                      const SizedBox(width: 6),
                      DcnChip(label: a.department, tone: DcnTone.brand, size: DcnButtonSize.sm),
                    ]),
                    Text('${a.school} · ${a.level} · ${a.appliedLabel}', style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          if (a.subUnitPref.isNotEmpty || a.responsibilities.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'Wants: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.text)),
              TextSpan(text: [a.subUnitPref, a.responsibilities.join(', ')].where((s) => s.isNotEmpty).join(' · '), style: TextStyle(fontSize: 12, color: c.textMuted)),
            ])),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DcnButton(label: 'Decline', variant: DcnButtonVariant.ghost, icon: 'x', full: true, onPressed: () => onDecide(a, false))),
            const SizedBox(width: 8),
            Expanded(child: DcnButton(label: 'Approve', variant: DcnButtonVariant.success, icon: 'check', full: true, onPressed: () => onDecide(a, true))),
          ]),
        ],
      ),
    );
  }
}
