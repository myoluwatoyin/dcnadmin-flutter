import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/member.dart';
import '../../../models/team_worker.dart';
import '../../hod/data/hod_providers.dart';
import '../../hod/widgets/hod_widgets.dart';
import '../data/fu_hod_providers.dart';

// ── Workers board ────────────────────────────────────────────
class FuHodWorkersScreen extends ConsumerStatefulWidget {
  const FuHodWorkersScreen({super.key});
  @override
  ConsumerState<FuHodWorkersScreen> createState() => _State();
}

class _State extends ConsumerState<FuHodWorkersScreen> {
  String _sort = 'perf';
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final team = [...(ref.watch(hodTeamProvider).valueOrNull ?? const <TeamWorker>[])];
    final onTrack = team.where((w) => w.fuQueueDonePct >= 70).length;
    final list = team.where((w) => _q.isEmpty || w.name.toLowerCase().contains(_q.toLowerCase())).toList();
    list.sort((a, b) {
      if (_sort == 'name') return a.name.compareTo(b.name);
      if (_sort == 'reports') {
        final ra = (a.bibleReport ? 1 : 0) + (a.prayerReport ? 1 : 0);
        final rb = (b.bibleReport ? 1 : 0) + (b.prayerReport ? 1 : 0);
        return rb.compareTo(ra);
      }
      return b.fuQueueDonePct.compareTo(a.fuQueueDonePct);
    });

    return Column(
      children: [
        DcnHeaderBar(title: 'FU workers', sub: '${team.length} on team · $onTrack on track'),
        Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              DcnField(icon: 'search', placeholder: 'Find a worker…', onChanged: (v) => setState(() => _q = v)),
              const SizedBox(height: 10),
              DcnSegmented(
                small: true,
                options: const [(id: 'perf', label: 'By performance'), (id: 'name', label: 'By name'), (id: 'reports', label: 'By reports')],
                value: _sort,
                onChanged: (v) => setState(() => _sort = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const DcnEmptyState(icon: 'users', title: 'No workers', body: 'No FU workers match.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _WorkerCard(w: list[i], onTap: () => context.push('/fh/worker/${list[i].uid}')),
                ),
        ),
      ],
    );
  }
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({required this.w, required this.onTap});
  final TeamWorker w;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final color = w.fuQueueDonePct >= 70 ? c.success : w.fuQueueDonePct >= 40 ? c.warning : c.danger;
    return DcnCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DcnAvatar(name: w.name, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(child: Text(w.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text))),
                      if (w.isSubHod) ...[const SizedBox(width: 6), const DcnChip(label: 'Sub-HOD', tone: DcnTone.brand, size: DcnButtonSize.sm)],
                    ]),
                    Text(w.subUnit, style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [
            StatusPill(icon: w.bibleReport ? 'check' : 'x', label: 'Bible', ok: w.bibleReport),
            StatusPill(icon: w.prayerReport ? 'check' : 'x', label: 'Prayer', ok: w.prayerReport),
            StatusPill(icon: 'users', label: '${w.fuContacted}/${w.fuAssigned}', ok: w.fuQueueDonePct >= 70, warn: w.fuQueueDonePct < 40),
            StatusPill(icon: 'phone', label: '${w.fuUnreachableHandled} unreach', ok: true),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: w.fuQueueDonePct / 100, minHeight: 6, backgroundColor: c.surface2, valueColor: AlwaysStoppedAnimation(color)),
          ),
        ],
      ),
    );
  }
}

// ── Worker detail ────────────────────────────────────────────
class FuHodWorkerDetailScreen extends ConsumerWidget {
  const FuHodWorkerDetailScreen({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final w = ref.watch(hodWorkerByIdProvider(uid));
    if (w == null) {
      return Scaffold(backgroundColor: c.bg, body: SafeArea(child: Column(children: [DcnHeaderBar(title: 'FU Worker', onBack: () => context.pop()), const Expanded(child: DcnEmptyState(icon: 'user', title: 'Not found', body: ''))])));
    }
    final color = w.fuQueueDonePct >= 70 ? c.success : c.warning;
    // Members currently assigned to this worker.
    final members = (ref.watch(allMembersProvider).valueOrNull ?? const <Member>[])
        .where((m) => m.assignedWorkerUid == uid)
        .toList();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DcnHeaderBar(title: 'FU Worker', onBack: () => context.pop()),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    DcnAvatar(name: w.name, size: 84),
                    const SizedBox(height: 12),
                    Text(w.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.text)),
                    const SizedBox(height: 4),
                    Text(w.subUnit, style: TextStyle(fontSize: 13.5, color: c.textMuted)),
                    const SizedBox(height: 10),
                    DcnChip(label: '${w.fuQueueDonePct}% this week', tone: w.fuQueueDonePct >= 70 ? DcnTone.success : DcnTone.warning),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(child: _Action(icon: 'user', label: 'Assign more', tone: DcnTone.brand, onTap: () => context.push('/fh/assign?worker=$uid'))),
                  const SizedBox(width: 8),
                  Expanded(child: _Action(icon: 'award', label: 'Score Q2', tone: DcnTone.warning, onTap: () => context.push('/hod/scorecard-entry/$uid'))),
                  const SizedBox(width: 8),
                  Expanded(child: _Action(icon: 'msg', label: 'Message', tone: DcnTone.info, onTap: () {})),
                ]),
              ),
              const DcnSectionHeader(title: "This week's queue"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DcnCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text.rich(TextSpan(children: [
                            TextSpan(text: '${w.fuContacted}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.text)),
                            TextSpan(text: '/${w.fuAssigned} contacted', style: TextStyle(fontSize: 14, color: c.textDim)),
                          ])),
                          DcnChip(label: '${w.fuQueueDonePct}%', tone: w.fuQueueDonePct >= 70 ? DcnTone.success : DcnTone.warning),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: w.fuQueueDonePct / 100, minHeight: 8, backgroundColor: c.surface2, valueColor: AlwaysStoppedAnimation(color))),
                    ],
                  ),
                ),
              ),
              const DcnSectionHeader(title: 'This week reports'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(child: _ReportTile(ok: w.bibleReport, icon: 'bookOpen', label: w.bibleReport ? 'Bible submitted' : 'Bible missed')),
                  const SizedBox(width: 8),
                  Expanded(child: _ReportTile(ok: w.prayerReport, icon: 'flame', label: w.prayerReport ? 'Prayer submitted' : 'Prayer missed')),
                ]),
              ),
              const DcnSectionHeader(title: 'Past 4 weeks · queue completion'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DcnCard(
                  child: SizedBox(
                    height: 90,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < 4; i++)
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  height: (([58, 72, 81, w.fuQueueDonePct][i]) / 100) * 60 + 10,
                                  decoration: BoxDecoration(color: c.brand.withValues(alpha: i == 3 ? 1 : 0.4), borderRadius: BorderRadius.circular(6)),
                                ),
                                const SizedBox(height: 6),
                                Text('W${17 + i}', style: TextStyle(fontSize: 10, color: c.textMuted, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (members.isNotEmpty) ...[
                const DcnSectionHeader(title: 'Members assigned'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      for (final m in members.take(6))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: DcnCard(
                            onTap: () => context.push('/fu/member/${m.id}'),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                DcnAvatar(name: m.name, size: 32),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
                                      Text(m.status, style: TextStyle(fontSize: 11, color: c.textMuted)),
                                    ],
                                  ),
                                ),
                                DcnChip(
                                  label: m.unreachable ? 'Unreachable' : m.isAtRisk ? '${m.weeksAbsent}w' : 'Active',
                                  tone: m.unreachable ? DcnTone.danger : m.isAtRisk ? DcnTone.warning : DcnTone.success,
                                  size: DcnButtonSize.sm,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ] else
                const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.tone, required this.onTap});
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
        child: Column(children: [
          Icon(switch (icon) { 'user' => Icons.person_outline, 'award' => Icons.emoji_events_outlined, _ => Icons.chat_bubble_outline }, size: 20, color: t.fg),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.fg)),
        ]),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.ok, required this.icon, required this.label});
  final bool ok;
  final String icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final fg = ok ? c.success : c.danger;
    final bg = ok ? c.successSoft : c.dangerSoft;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon == 'bookOpen' ? Icons.menu_book_outlined : Icons.local_fire_department_outlined, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg))),
        ],
      ),
    );
  }
}
