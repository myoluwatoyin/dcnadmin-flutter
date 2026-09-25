import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_sheet.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/team_worker.dart';
import '../data/hod_providers.dart';

class HodAssignTaskScreen extends ConsumerStatefulWidget {
  const HodAssignTaskScreen({super.key, this.presetWorker});
  final String? presetWorker;
  @override
  ConsumerState<HodAssignTaskScreen> createState() => _State();
}

class _State extends ConsumerState<HodAssignTaskScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _due = TextEditingController();
  String _priority = 'MEDIUM';
  final Set<String> _assignees = {};
  bool _notifySms = true;
  bool _busy = false;
  bool _seeded = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _due.dispose();
    super.dispose();
  }

  Future<void> _submit(List<TeamWorker> team) async {
    if (_title.text.trim().isEmpty || _due.text.trim().isEmpty || _assignees.isEmpty) return;
    final dept = ref.read(hodDeptProvider);
    final by = ref.read(authStateProvider).valueOrNull?.fullName ?? 'HOD';
    if (dept == null) return;
    setState(() => _busy = true);
    try {
      final picked = team.where((w) => _assignees.contains(w.uid)).map((w) => (uid: w.uid, name: w.name)).toList();
      await ref.read(hodRepositoryProvider).assignTask(
            dept: dept,
            assignedBy: '$by (HOD)',
            title: _title.text,
            description: _desc.text,
            dueDate: _due.text,
            priority: _priority,
            assignees: picked,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Task assigned to ${picked.length} ${picked.length == 1 ? 'person' : 'people'}'),
          behavior: SnackBarBehavior.floating,
        ));
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not assign. Try again.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final team = ref.watch(hodTeamProvider).valueOrNull ?? const <TeamWorker>[];
    if (!_seeded && widget.presetWorker != null && team.any((w) => w.uid == widget.presetWorker)) {
      _assignees.add(widget.presetWorker!);
      _seeded = true;
    }
    final subUnits = <String>{for (final w in team) if (w.subUnit.isNotEmpty) w.subUnit}.toList()..sort();
    final valid = _title.text.trim().isNotEmpty && _due.text.trim().isNotEmpty && _assignees.isNotEmpty;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Assign task', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DcnField(label: 'Task title', controller: _title, placeholder: 'What needs doing?', onChanged: (_) => setState(() {})),
                    const SizedBox(height: 12),
                    DcnField(label: 'Description', controller: _desc, placeholder: 'Details, links, expectations…', multiline: true),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: DcnField(label: 'Due date', controller: _due, icon: 'calendar', placeholder: 'Thu, 21 May', onChanged: (_) => setState(() {})),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted)),
                              const SizedBox(height: 6),
                              DcnSegmented(
                                small: true,
                                options: const [(id: 'LOW', label: 'Low'), (id: 'MEDIUM', label: 'Med'), (id: 'HIGH', label: 'High')],
                                value: _priority,
                                onChanged: (v) => setState(() => _priority = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const DcnSectionHeader(title: 'Assign to'),
                    GestureDetector(
                      onTap: () => _openPicker(team),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          children: [
                            DcnIcon('users', size: 18, color: c.brand),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _assignees.isEmpty
                                    ? 'Pick workers, sub-unit, or whole dept'
                                    : _assignees.length == 1
                                        ? team.firstWhere((w) => w.uid == _assignees.first, orElse: () => team.first).name
                                        : '${_assignees.length} workers selected',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text),
                              ),
                            ),
                            DcnIcon('chevronRight', size: 18, color: c.textDim),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _QuickPick(label: 'Whole dept', onTap: () => setState(() => _assignees
                          ..clear()
                          ..addAll(team.map((w) => w.uid)))),
                        for (final su in subUnits)
                          _QuickPick(
                            label: su,
                            onTap: () => setState(() => _assignees
                              ..clear()
                              ..addAll(team.where((w) => w.subUnit == su).map((w) => w.uid))),
                          ),
                      ],
                    ),
                    if (_assignees.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final uid in _assignees)
                            if (team.any((w) => w.uid == uid))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(999)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(team.firstWhere((w) => w.uid == uid).name,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.brandInk)),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => setState(() => _assignees.remove(uid)),
                                      child: DcnIcon('x', size: 12, color: c.brandInk),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ],
                    const DcnSectionHeader(title: 'Notify them'),
                    DcnCard(
                      child: Row(
                        children: [
                          DcnIcon('msg', size: 18, color: c.brand),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SMS notification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
                                Text('In-app push is always sent', style: TextStyle(fontSize: 12, color: c.textMuted)),
                              ],
                            ),
                          ),
                          DcnToggle(value: _notifySms, onChanged: (v) => setState(() => _notifySms = v)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: DcnButton(
                label: _assignees.isEmpty ? 'Assign' : 'Assign (${_assignees.length})',
                icon: 'send',
                size: DcnButtonSize.lg,
                full: true,
                loading: _busy,
                onPressed: valid && !_busy ? () => _submit(team) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPicker(List<TeamWorker> team) {
    showDcnSheet<void>(
      context: context,
      title: 'Pick workers',
      builder: (ctx) {
        final c = ctx.dcn;
        return StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            children: [
              for (final w in team)
                InkWell(
                  onTap: () => setSheet(() {
                    if (_assignees.contains(w.uid)) {
                      _assignees.remove(w.uid);
                    } else {
                      _assignees.add(w.uid);
                    }
                    setState(() {});
                  }),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: _assignees.contains(w.uid) ? c.brandSoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _assignees.contains(w.uid) ? c.brand : c.surface2,
                            borderRadius: BorderRadius.circular(6),
                            border: _assignees.contains(w.uid) ? null : Border.all(color: c.border, width: 1.5),
                          ),
                          child: _assignees.contains(w.uid) ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 12),
                        DcnAvatar(name: w.name, size: 36),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text)),
                              Text('${w.subUnit} · ${w.tasksOpen} open', style: TextStyle(fontSize: 11, color: c.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              DcnButton(label: 'Done', full: true, onPressed: () => Navigator.of(ctx).pop()),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _QuickPick extends StatelessWidget {
  const _QuickPick({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DcnIcon('plus', size: 11, color: c.textMuted),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textMuted)),
          ],
        ),
      ),
    );
  }
}
