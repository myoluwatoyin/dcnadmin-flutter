import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/department.dart';
import '../../../models/member.dart';
import '../../../models/team_worker.dart';
import '../../hod/data/hod_providers.dart';
import '../data/fu_hod_providers.dart';
import '../widgets/fu_widgets.dart';

class FuHodAssignScreen extends ConsumerStatefulWidget {
  const FuHodAssignScreen({super.key, this.presetMember, this.presetWorker});
  final String? presetMember;
  final String? presetWorker;
  @override
  ConsumerState<FuHodAssignScreen> createState() => _State();
}

class _State extends ConsumerState<FuHodAssignScreen> {
  String _step = 'members';
  final Set<String> _members = {};
  final Set<String> _workers = {};
  String _priority = 'med';
  final _reason = TextEditingController();
  String _memberFilter = 'ALL';
  String _memberQ = '';
  String _scope = 'FU'; // FU | ANY
  String _dept = 'ALL';
  String _workerQ = '';
  bool _busy = false;
  bool _seeded = false;

  static const _order = ['members', 'workers', 'brief'];

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool _matchMember(Member m) {
    if (_memberFilter == 'AT_RISK' && !m.isAtRisk) return false;
    if (_memberFilter == 'FIRST' && !m.isFirstTimer) return false;
    if (_memberFilter == 'UNREACH' && !m.unreachable) return false;
    if (_memberQ.isNotEmpty && !m.name.toLowerCase().contains(_memberQ.toLowerCase())) return false;
    return true;
  }

  bool get _canContinue => switch (_step) {
        'members' => _members.isNotEmpty,
        'workers' => _workers.isNotEmpty,
        _ => _reason.text.trim().isNotEmpty,
      };

  Future<void> _submit(List<Member> allMembers) async {
    final by = ref.read(authStateProvider).valueOrNull?.fullName ?? 'FU HOD';
    setState(() => _busy = true);
    try {
      final picked = allMembers.where((m) => _members.contains(m.id)).map((m) => (id: m.id, name: m.name)).toList();
      await ref.read(fuHodRepositoryProvider).assignFollowup(
            members: picked,
            workerUids: _workers.toList(),
            priority: _priority,
            reason: _reason.text,
            assignedBy: '$by (FU HOD)',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${picked.length} member(s) assigned to ${_workers.length} worker(s)'),
          behavior: SnackBarBehavior.floating,
        ));
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not assign. Try again.'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final allMembers = ref.watch(allMembersProvider).valueOrNull ?? const <Member>[];
    final fuTeam = ref.watch(hodTeamProvider).valueOrNull ?? const <TeamWorker>[];
    final allWorkers = ref.watch(allWorkersProvider).valueOrNull ?? const <WorkerRef>[];

    if (!_seeded) {
      if (widget.presetMember != null) _members.add(widget.presetMember!);
      if (widget.presetWorker != null) _workers.add(widget.presetWorker!);
      _seeded = true;
    }

    final stepIdx = _order.indexOf(_step);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(
              title: 'Assign follow-up',
              sub: 'Step ${stepIdx + 1} of 3 · ${switch (_step) { 'members' => 'Pick members', 'workers' => 'Pick worker(s)', _ => 'Brief' }}',
              onBack: () => _step == 'members' ? context.pop() : setState(() => _step = _order[stepIdx - 1]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(children: [
                for (var i = 0; i < 3; i++) ...[
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: i <= stepIdx ? c.brand : c.border, borderRadius: BorderRadius.circular(99)))),
                  if (i < 2) const SizedBox(width: 4),
                ],
              ]),
            ),
            Expanded(child: switch (_step) {
              'members' => _membersStep(c, allMembers),
              'workers' => _workersStep(c, fuTeam, allWorkers),
              _ => _briefStep(c, allMembers),
            }),
            Container(
              decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  if (_step != 'members') DcnButton(label: 'Back', variant: DcnButtonVariant.ghost, onPressed: () => setState(() => _step = _order[stepIdx - 1])),
                  if (_step != 'members') const SizedBox(width: 10),
                  Expanded(
                    child: _step != 'brief'
                        ? DcnButton(
                            label: 'Continue${_step == 'members' ? ' (${_members.length})' : ' (${_workers.length})'}',
                            iconRight: 'arrowRight',
                            size: DcnButtonSize.lg,
                            full: true,
                            onPressed: _canContinue ? () => setState(() => _step = _order[stepIdx + 1]) : null,
                          )
                        : DcnButton(label: 'Assign & notify', icon: 'send', size: DcnButtonSize.lg, full: true, loading: _busy, onPressed: _canContinue && !_busy ? () => _submit(allMembers) : null),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _membersStep(DcnColors c, List<Member> allMembers) {
    final filtered = allMembers.where(_matchMember).toList();
    return Column(
      children: [
        Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            children: [
              DcnField(icon: 'search', placeholder: 'Find a member…', onChanged: (v) => setState(() => _memberQ = v)),
              const SizedBox(height: 10),
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final f in const [(id: 'ALL', label: 'All'), (id: 'AT_RISK', label: 'At risk'), (id: 'FIRST', label: 'First-timers'), (id: 'UNREACH', label: 'Unreachable')])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _memberFilter = f.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: _memberFilter == f.id ? c.brand : c.surface2, borderRadius: BorderRadius.circular(999)),
                            child: Text(f.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _memberFilter == f.id ? Colors.white : c.textMuted)),
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
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final m = filtered[i];
              final checked = _members.contains(m.id);
              final s = memberStatus(m);
              return _pickRow(
                c,
                checked: checked,
                onTap: () => setState(() => checked ? _members.remove(m.id) : _members.add(m.id)),
                name: m.name,
                sub: '${m.school} · last: ${m.lastAttended}',
                chip: DcnChip(label: s.label, tone: s.tone, size: DcnButtonSize.sm),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _workersStep(DcnColors c, List<TeamWorker> fuTeam, List<WorkerRef> allWorkers) {
    final anyFiltered = allWorkers.where((w) {
      if (_dept != 'ALL' && (w.departmentName ?? '') != _dept) return false;
      if (_workerQ.isNotEmpty && !w.name.toLowerCase().contains(_workerQ.toLowerCase())) return false;
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        DcnSegmented(
          options: const [(id: 'FU', label: 'Follow-Up team'), (id: 'ANY', label: 'Any worker · all depts')],
          value: _scope,
          onChanged: (v) => setState(() {
            _scope = v;
            _workers.clear();
          }),
        ),
        const SizedBox(height: 14),
        if (_scope == 'FU')
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.infoSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.info.withValues(alpha: 0.4))),
            child: Row(
              children: [
                DcnIcon('sparkle', size: 18, color: c.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Smart-assign', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.info)),
                      Text('Route to the FU worker with the lightest queue.', style: TextStyle(fontSize: 11.5, color: c.text)),
                    ],
                  ),
                ),
                DcnButton(
                  label: 'Use',
                  size: DcnButtonSize.sm,
                  onPressed: () {
                    if (fuTeam.isEmpty) return;
                    final lightest = [...fuTeam]..sort((a, b) => a.fuAssigned.compareTo(b.fuAssigned));
                    setState(() {
                      _workers
                        ..clear()
                        ..add(lightest.first.uid);
                    });
                  },
                ),
              ],
            ),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.warningSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.warning.withValues(alpha: 0.4))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DcnIcon('users', size: 18, color: c.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cross-dept assignment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.warning)),
                      Text('The worker gets it in their dashboard (separate from HOD tasks) + push + SMS. Best for shared interests or overflow.', style: TextStyle(fontSize: 11.5, color: c.text)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DcnField(icon: 'search', placeholder: 'Find a worker by name…', onChanged: (v) => setState(() => _workerQ = v)),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final d in const ['ALL', 'Drama', 'Media', 'Worship', 'Ushering', 'Technical', 'Follow-Up'])
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
        const SizedBox(height: 14),
        if (_scope == 'FU')
          for (final w in fuTeam)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _pickRow(
                c,
                checked: _workers.contains(w.uid),
                onTap: () => setState(() => _workers.contains(w.uid) ? _workers.remove(w.uid) : _workers.add(w.uid)),
                name: w.name,
                sub: w.subUnit,
                trailing: Text('${w.fuAssigned}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.text)),
              ),
            )
        else
          for (final w in anyFiltered)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _pickRow(
                c,
                checked: _workers.contains(w.id),
                onTap: () => setState(() => _workers.contains(w.id) ? _workers.remove(w.id) : _workers.add(w.id)),
                name: w.name,
                sub: '${w.departmentName ?? ''}${w.subUnitName != null ? ' · ${w.subUnitName}' : ''}',
                chip: w.role != null ? DcnChip(label: w.role!, tone: DcnTone.neutral, size: DcnButtonSize.sm) : null,
              ),
            ),
      ],
    );
  }

  Widget _briefStep(DcnColors c, List<Member> allMembers) {
    final names = allMembers.where((m) => _members.contains(m.id)).map((m) => m.name).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        DcnCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("YOU'RE ASSIGNING", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.textMuted, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(children: [
                DcnChip(label: '${_members.length} member${_members.length == 1 ? '' : 's'}', tone: DcnTone.brand, icon: 'user'),
                const SizedBox(width: 8),
                DcnIcon('arrowRight', size: 14, color: c.textDim),
                const SizedBox(width: 8),
                DcnChip(label: '${_workers.length} worker${_workers.length == 1 ? '' : 's'}', tone: DcnTone.info, icon: 'users'),
              ]),
              if (names.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final n in names.take(6))
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(999)), child: Text(n, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textMuted))),
                    if (names.length > 6) Text('+${names.length - 6} more', style: TextStyle(fontSize: 11, color: c.textDim)),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted)),
        const SizedBox(height: 8),
        DcnSegmented(
          options: const [(id: 'low', label: 'Low'), (id: 'med', label: 'Med'), (id: 'high', label: 'High'), (id: 'urgent', label: 'Urgent')],
          value: _priority,
          onChanged: (v) => setState(() => _priority = v),
        ),
        const SizedBox(height: 16),
        DcnField(
          label: 'Why is this follow-up needed?',
          controller: _reason,
          placeholder: "e.g. Missed 3 Sundays — wants to know they're OK",
          multiline: true,
          hint: 'The worker sees this in their queue. Be specific.',
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _pickRow(
    DcnColors c, {
    required bool checked,
    required VoidCallback onTap,
    required String name,
    required String sub,
    DcnChip? chip,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: checked ? c.brandSoft : c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: checked ? c.brand : c.border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: checked ? c.brand : c.surface2, borderRadius: BorderRadius.circular(6), border: checked ? null : Border.all(color: c.border, width: 1.5)),
              child: checked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 10),
            DcnAvatar(name: name, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text)),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: c.textMuted)),
                ],
              ),
            ),
            if (chip != null) chip,
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
