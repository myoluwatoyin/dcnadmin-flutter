import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../data/pastor_providers.dart';

// ── Departments list ─────────────────────────────────────────
class PastorDepartmentsScreen extends ConsumerWidget {
  const PastorDepartmentsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final depts = ref.watch(deptHealthProvider);
    return Column(
      children: [
        const DcnHeaderBar(title: 'Departments', sub: 'All 6 at a glance'),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: depts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final d = depts[i];
              final tone = d.health == 'GOOD' ? DcnTone.success : d.health == 'WATCH' ? DcnTone.warning : DcnTone.danger;
              return DcnCard(
                onTap: () => context.push('/p/dept/${d.code}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: d.color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(14)), child: Text(d.name[0], style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: d.color))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(d.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.text)),
                                const SizedBox(width: 6),
                                DcnChip(label: d.health, tone: tone, size: DcnButtonSize.sm),
                              ]),
                              Text('HOD: ${d.hod} · ${d.workers} workers', style: TextStyle(fontSize: 12, color: c.textMuted)),
                            ],
                          ),
                        ),
                        DcnIcon('chevronRight', size: 20, color: c.textDim),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: c.divider, height: 1),
                    const SizedBox(height: 12),
                    Row(children: [
                      _MiniCol(label: 'Reports', value: '${d.reportsPct}%', ok: d.reportsPct >= 75),
                      _MiniCol(label: 'Attendance', value: '${d.attendancePct}%', ok: d.attendancePct >= 80),
                      _MiniCol(label: 'Overdue', value: '${d.tasksOverdue}', ok: d.tasksOverdue == 0, warn: d.tasksOverdue > 0),
                    ]),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniCol extends StatelessWidget {
  const _MiniCol({required this.label, required this.value, this.ok = false, this.warn = false});
  final String label;
  final String value;
  final bool ok;
  final bool warn;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final color = ok ? c.success : warn ? c.warning : c.text;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.textMuted)),
        ],
      ),
    );
  }
}

// ── Dept detail ──────────────────────────────────────────────
class PastorDeptDetailScreen extends ConsumerWidget {
  const PastorDeptDetailScreen({super.key, required this.code});
  final String code;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final d = ref.watch(deptHealthByCodeProvider(code));
    if (d == null) {
      return Scaffold(backgroundColor: c.bg, body: SafeArea(child: Column(children: [DcnHeaderBar(title: 'Department', onBack: () => context.pop()), const Expanded(child: DcnEmptyState(icon: 'grid', title: 'Not found', body: ''))])));
    }
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: d.name, sub: 'HOD: ${d.hod}', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [d.color, Color.lerp(d.color, Colors.black, 0.15)!])),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)), child: Text(d.health == 'GOOD' ? 'Good standing' : d.health == 'WATCH' ? 'On watch' : 'At risk', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
                        const SizedBox(height: 10),
                        Text(d.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.6)),
                        const SizedBox(height: 6),
                        Text('${d.workers} workers · HOD: ${d.hod}', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
                      ],
                    ),
                  ),
                  const DcnSectionHeader(title: 'Health metrics'),
                  Row(children: [
                    Expanded(child: DcnStatTile(label: 'Reports', value: '${d.reportsPct}%', icon: 'bookOpen', tone: d.reportsPct >= 75 ? DcnTone.success : DcnTone.warning)),
                    const SizedBox(width: 8),
                    Expanded(child: DcnStatTile(label: 'Attendance', value: '${d.attendancePct}%', icon: 'checkCircle', tone: d.attendancePct >= 80 ? DcnTone.success : DcnTone.warning)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: DcnStatTile(label: 'Tasks overdue', value: '${d.tasksOverdue}', icon: 'clock', tone: d.tasksOverdue == 0 ? DcnTone.success : DcnTone.danger)),
                    const SizedBox(width: 8),
                    Expanded(child: DcnStatTile(label: 'Scorecards', value: '${d.scorecardsDone}', sub: 'Q2 done', icon: 'award', tone: DcnTone.brand)),
                  ]),
                  const DcnSectionHeader(title: 'Actions'),
                  DcnCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(children: [
                      _action(context, c, 'msg', 'Message ${d.hod}', 'Direct message', () {}, divider: true),
                      _action(context, c, 'send', 'Send dept blast', 'In-app + SMS', () => context.push('/fh/sms-blast'), divider: true),
                      _action(context, c, 'award', 'Scorecard analytics', 'Per-worker breakdown', () => context.push('/p/scorecards'), divider: false),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext ctx, DcnColors c, String icon, String title, String sub, VoidCallback onTap, {required bool divider}) => Container(
        decoration: BoxDecoration(border: divider ? Border(bottom: BorderSide(color: c.divider)) : null),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(children: [
              Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(10)), child: DcnIcon(icon, size: 18, color: c.brand)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
                Text(sub, style: TextStyle(fontSize: 12, color: c.textMuted)),
              ])),
              DcnIcon('chevronRight', size: 18, color: c.textDim),
            ]),
          ),
        ),
      );
}
