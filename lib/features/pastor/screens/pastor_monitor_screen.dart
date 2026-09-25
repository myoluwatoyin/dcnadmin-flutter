import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/member.dart';
import '../../followup/data/fu_hod_providers.dart';
import '../../followup/widgets/fu_widgets.dart';
import '../data/pastor_providers.dart';

// ── Follow-up monitor ────────────────────────────────────────
class PastorFollowupMonitorScreen extends ConsumerStatefulWidget {
  const PastorFollowupMonitorScreen({super.key});
  @override
  ConsumerState<PastorFollowupMonitorScreen> createState() => _State();
}

class _State extends ConsumerState<PastorFollowupMonitorScreen> {
  String _tab = 'ACTIVE';
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final members = ref.watch(allMembersProvider).valueOrNull ?? const <Member>[];
    final analytics = ref.watch(analyticsProvider).valueOrNull ?? const {};
    final ret = (analytics['retention'] as Map?) ?? const {};

    final firstTimers = members.where((m) => m.isFirstTimer).toList();
    final atRisk = members.where((m) => m.isAtRisk || m.unreachable).toList();
    final done = members.where((m) => m.queueDone).toList();
    final active = members.where((m) => !m.isFirstTimer && !m.isAtRisk && !m.unreachable && !m.queueDone).toList();
    final shown = switch (_tab) { 'FIRST' => firstTimers, 'AT_RISK' => atRisk, 'DONE' => done, _ => active };

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Follow-up monitor', sub: 'Church-wide', onBack: () => context.pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.brand, c.brandDeep])),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('90-DAY RETENTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.85), letterSpacing: 0.5)),
                          Text('${(ret['retained_pct'] ?? 0)}%', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                          Text('${(ret['returned'] ?? 0)} of ${(ret['first_timers_90d'] ?? 0)} first-timers returning', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${(ret['at_risk_recovered'] ?? 0)}/${(ret['at_risk_total'] ?? 0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text('at-risk recovered', style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.8))),
                        const SizedBox(height: 8),
                        Text('${(ret['avg_contact_days'] ?? 0)}d', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text('avg to contact', style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.8))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: c.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: DcnSegmented(
                small: true,
                options: [
                  (id: 'ACTIVE', label: 'Active (${active.length})'),
                  (id: 'FIRST', label: 'First (${firstTimers.length})'),
                  (id: 'AT_RISK', label: 'At-risk (${atRisk.length})'),
                  (id: 'DONE', label: 'Done (${done.length})'),
                ],
                value: _tab,
                onChanged: (v) => setState(() => _tab = v),
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? const DcnEmptyState(icon: 'checkCircle', title: 'Nothing here', body: 'No cases in this view.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: shown.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => MemberRow(member: shown[i], onTap: () => context.push('/fu/member/${shown[i].id}')),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SMS dashboard ────────────────────────────────────────────
class PastorSmsDashboardScreen extends ConsumerWidget {
  const PastorSmsDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final a = ref.watch(analyticsProvider).valueOrNull ?? const {};
    final sms = (a['sms'] as Map?) ?? const {};
    final blasts = ((a['blasts'] as List?) ?? const []).cast<Map>();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'SMS dashboard', sub: 'Church-wide', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  DcnCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${sms['sent'] ?? 0}', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: c.text)),
                            Text('sent this month · ${sms['cost_month'] ?? ''}', style: TextStyle(fontSize: 12, color: c.textMuted)),
                          ]),
                          DcnChip(label: '${sms['rate'] ?? 0}% delivered', tone: DcnTone.success, icon: 'check'),
                        ]),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: _stat(c, 'Delivered', '${sms['delivered'] ?? 0}', DcnTone.success)),
                          const SizedBox(width: 8),
                          Expanded(child: _stat(c, 'Pending', '${sms['pending'] ?? 0}', DcnTone.info)),
                          const SizedBox(width: 8),
                          Expanded(child: _stat(c, 'Failed', '${sms['failed'] ?? 0}', DcnTone.danger)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: DcnButton(label: 'New blast', icon: 'send', full: true, onPressed: () => context.push('/fh/sms-blast'))),
                    const SizedBox(width: 10),
                    Expanded(child: DcnButton(label: 'SMS log', variant: DcnButtonVariant.ghost, icon: 'list', full: true, onPressed: () => context.push('/fh/sms-log'))),
                  ]),
                  const DcnSectionHeader(title: 'Recent blasts'),
                  for (final b in blasts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DcnCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${b['name']}', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text)),
                                Text('${b['audience']} · ${b['count']} · ${b['at']}', style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                              ],
                            ),
                          ),
                          DcnChip(label: '${b['status']}'.toLowerCase() == 'scheduled' ? 'Scheduled' : 'Sent', tone: '${b['status']}'.toLowerCase() == 'scheduled' ? DcnTone.info : DcnTone.success, size: DcnButtonSize.sm),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(DcnColors c, String label, String v, DcnTone tone) {
    final fg = switch (tone) { DcnTone.success => c.success, DcnTone.info => c.info, _ => c.danger };
    final bg = switch (tone) { DcnTone.success => c.successSoft, DcnTone.info => c.infoSoft, _ => c.dangerSoft };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(v, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: fg)),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }
}
