import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../worker/widgets/worker_rows.dart';
import '../data/hod_providers.dart';
import '../widgets/hod_widgets.dart';

class HodWorkerDetailScreen extends ConsumerStatefulWidget {
  const HodWorkerDetailScreen({super.key, required this.uid});
  final String uid;
  @override
  ConsumerState<HodWorkerDetailScreen> createState() => _State();
}

class _State extends ConsumerState<HodWorkerDetailScreen> {
  String _tab = 'overview';

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final w = ref.watch(hodWorkerByIdProvider(widget.uid));

    if (w == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(
            children: [
              DcnHeaderBar(title: 'Worker', onBack: () => context.pop()),
              const Expanded(child: DcnEmptyState(icon: 'user', title: 'Not found', body: 'This worker is no longer on the team.')),
            ],
          ),
        ),
      );
    }

    final firstName = w.name.split(' ').first;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Worker', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Column(
                        children: [
                          DcnAvatar(name: w.name, size: 84),
                          const SizedBox(height: 12),
                          Text(w.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.text)),
                          const SizedBox(height: 4),
                          Text('${w.subUnit} · ${w.weeksWithUs}w in dept',
                              style: TextStyle(fontSize: 13.5, color: c.textMuted)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            children: [
                              if (w.isSubHod) const DcnChip(label: 'Sub-HOD', tone: DcnTone.brand),
                              if (w.atRisk) const DcnChip(label: 'At risk', tone: DcnTone.danger, icon: 'alert'),
                              DcnChip(label: '${w.attendanceRate}% attendance', tone: DcnTone.neutral),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(child: _ActionBtn(icon: 'plus', label: 'Assign', tone: DcnTone.brand, onTap: () => context.push('/hod/assign?worker=${w.uid}'))),
                          const SizedBox(width: 8),
                          Expanded(child: _ActionBtn(icon: 'msg', label: 'Message', tone: DcnTone.info, onTap: () {})),
                          const SizedBox(width: 8),
                          Expanded(child: _ActionBtn(icon: 'phone', label: 'Call', tone: DcnTone.success, onTap: () {})),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DcnSegmented(
                        small: true,
                        options: const [
                          (id: 'overview', label: 'Overview'),
                          (id: 'attendance', label: 'Attendance'),
                          (id: 'scorecard', label: 'Scorecard'),
                        ],
                        value: _tab,
                        onChanged: (v) => setState(() => _tab = v),
                      ),
                    ),
                    if (_tab == 'overview') _overview(context, w),
                    if (_tab == 'attendance') _attendance(context, w),
                    if (_tab == 'scorecard') _scorecard(context, w),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: DcnButton(
                label: 'Assign task to $firstName',
                icon: 'plus',
                size: DcnButtonSize.lg,
                full: true,
                onPressed: () => context.push('/hod/assign?worker=${w.uid}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overview(BuildContext context, w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DcnSectionHeader(title: 'This week'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DcnCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(icon: w.bibleReport ? 'check' : 'x', label: 'Bible report', ok: w.bibleReport),
                StatusPill(icon: w.prayerReport ? 'check' : 'x', label: 'Prayer report', ok: w.prayerReport),
                StatusPill(
                  icon: 'clipboard',
                  label: '${w.tasksOpen} open tasks',
                  ok: w.tasksOverdue == 0,
                  warn: w.tasksOverdue > 0,
                  sub: w.tasksOverdue > 0 ? '${w.tasksOverdue} overdue' : null,
                ),
              ],
            ),
          ),
        ),
        const DcnSectionHeader(title: 'Recent activity'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            children: const [
              ActivityItem(icon: 'send', tone: DcnTone.success, title: 'Submitted weekly reports', sub: 'This week'),
              ActivityItem(icon: 'check', tone: DcnTone.success, title: 'A task was approved', sub: 'Recently'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _attendance(BuildContext context, w) {
    final c = context.dcn;
    // Deterministic 12-session pattern from the worker's rate.
    final present = (w.attendanceRate / 100 * 12).round();
    final cells = List.generate(12, (i) => i < present);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DcnSectionHeader(title: 'Attendance · last 12 sessions'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DcnCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (final on in cells)
                      Expanded(
                        child: Container(
                          height: 32,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: on ? c.success : c.dangerSoft,
                            borderRadius: BorderRadius.circular(4),
                            border: on ? null : Border.all(color: c.danger, style: BorderStyle.solid),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('$present of 12 sessions (${w.attendanceRate}%)',
                    style: TextStyle(fontSize: 12, color: c.textMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _scorecard(BuildContext context, w) {
    final c = context.dcn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DcnSectionHeader(title: 'Last quarter'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DcnCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LAST SCORE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.textMuted, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text('${w.scorecardLast}/100',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: w.scorecardLast >= 50 ? c.success : c.danger)),
                  ],
                ),
                DcnChip(
                  label: w.scorecardLast >= 50 ? 'Passed' : 'Below pass',
                  tone: w.scorecardLast >= 50 ? DcnTone.success : DcnTone.danger,
                ),
              ],
            ),
          ),
        ),
        const DcnSectionHeader(title: 'Q2 2026 assessment'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: DcnButton(
            label: 'Start Q2 assessment',
            icon: 'award',
            size: DcnButtonSize.lg,
            full: true,
            onPressed: () => context.push('/hod/scorecard-entry/${w.uid}'),
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label, required this.tone, required this.onTap});
  final String icon;
  final String label;
  final DcnTone tone;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = toneColors(context, tone);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            DcnIcon(icon, size: 20, color: t.fg),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.fg)),
          ],
        ),
      ),
    );
  }
}
