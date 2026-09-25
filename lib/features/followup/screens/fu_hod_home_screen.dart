import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../chat/data/chat_providers.dart';

import '../../../core/providers.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_scroll_scaffold.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/member.dart';
import '../../../models/team_worker.dart';
import '../../hod/data/hod_providers.dart';
import '../../hod/widgets/hod_widgets.dart';
import '../../worker/data/worker_providers.dart';
import '../../worker/widgets/worker_rows.dart';
import '../data/fu_hod_providers.dart';

class FuHodHomeScreen extends ConsumerWidget {
  const FuHodHomeScreen({super.key, this.onOpenTab});
  final void Function(String tabId)? onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final user = ref.watch(authStateProvider).valueOrNull;
    final team = ref.watch(hodTeamProvider).valueOrNull ?? const <TeamWorker>[];
    final members = ref.watch(allMembersProvider).valueOrNull ?? const <Member>[];
    final absence = ref.watch(absenceQueueProvider);
    final unreachable = ref.watch(unreachableMembersProvider);
    final unread = ref.watch(workerUnreadCountProvider);
    final smsLog = ref.watch(smsLogProvider).valueOrNull ?? const [];

    final onTrack = team.where((w) => w.fuQueueDonePct >= 70).length;
    final completion = team.isEmpty
        ? 0
        : (team.fold<int>(0, (s, w) => s + w.fuQueueDonePct) / team.length).round();
    final firstTimers = members.where((m) => m.isFirstTimer).length;
    final atRisk = members.where((m) => m.isAtRisk).length;
    final smsSent = smsLog.length;
    final smsFailed = smsLog.where((l) => l.failed).length;

    Widget header(bool scrolled) => DcnHeaderBar(
          scrolled: scrolled,
          left: Padding(padding: const EdgeInsets.only(right: 4), child: DcnAvatar(name: user?.fullName ?? '?', size: 36)),
          title: 'Follow-Up HOD',
          sub: '${user?.fullName ?? ''} · ${members.length} members tracked',
          right: [
            HeaderIconButton(icon: 'msg', dot: ref.watch(chatUnreadCountProvider) > 0, onTap: () => context.push('/chat')),
            const SizedBox(width: 6),
            HeaderIconButton(icon: 'bell', dot: unread > 0, onTap: () => context.push('/notifications')),
          ],
        );

    return DcnScrollScaffold(
      header: header,
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Completion hero
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.brand, c.brandDeep]),
                boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 12))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("THIS WEEK'S FOLLOW-UP COMPLETION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.85), letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('$completion%', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('· $onTrack/${team.length} workers on track', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85)))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(value: completion / 100, minHeight: 6, backgroundColor: Colors.black.withValues(alpha: 0.18), valueColor: const AlwaysStoppedAnimation(Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          // Quick actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(children: [
              Row(children: [
                Expanded(child: QuickAction(icon: 'user', label: 'Assign follow-up', sub: 'Member → worker', tone: DcnTone.brand, onTap: () => context.push('/fh/assign'))),
                const SizedBox(width: 10),
                Expanded(child: QuickAction(icon: 'award', label: 'Score FU workers', sub: 'Q2 assessments', tone: DcnTone.warning, onTap: () => context.push('/hod/scorecards'))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: QuickAction(icon: 'bookOpen', label: 'Accountability', sub: 'Bible & prayer', tone: DcnTone.info, onTap: () => context.push('/hod/accountability'))),
                const SizedBox(width: 10),
                Expanded(child: QuickAction(icon: 'plus', label: 'Add member', sub: 'Manual · bulk · sync', tone: DcnTone.success, onTap: () => context.push('/fu/add-member'))),
              ]),
            ]),
          ),
          // Urgent cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(child: _UrgentCard(icon: 'alert', value: absence.length, label: 'Absence queue', tone: DcnTone.danger, onTap: () => context.push('/fh/absence'))),
              const SizedBox(width: 10),
              Expanded(child: _UrgentCard(icon: 'phone', value: unreachable.length, label: 'Unreachable', tone: DcnTone.warning, onTap: () => context.push('/fh/unreachable'))),
            ]),
          ),
          // Stats
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(child: DcnStatTile(label: 'Members', value: '${members.length}', sub: 'total', icon: 'users', tone: DcnTone.brand, onTap: () => onOpenTab?.call('members'))),
              const SizedBox(width: 8),
              Expanded(child: DcnStatTile(label: 'At risk', value: '$atRisk', sub: 'abs > 2w', icon: 'alert', tone: DcnTone.warning, onTap: () => context.push('/fh/absence'))),
              const SizedBox(width: 8),
              Expanded(child: DcnStatTile(label: 'First-timers', value: '$firstTimers', sub: 'active', icon: 'star', tone: DcnTone.info, onTap: () => context.push('/fu/first-timers'))),
            ]),
          ),
          // Worker performance roll-up
          DcnSectionHeader(title: 'My FU workers · this week', action: 'Full board', onAction: () => onOpenTab?.call('workers')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final w in team.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DcnCard(
                      onTap: () => context.push('/fh/worker/${w.uid}'),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          DcnAvatar(name: w.name, size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(w.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text)),
                                Text('${w.fuContacted}/${w.fuAssigned} contacted · ${w.subUnit}', style: TextStyle(fontSize: 11, color: c.textMuted)),
                              ],
                            ),
                          ),
                          _PctBadge(pct: w.fuQueueDonePct),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // SMS snapshot
          DcnSectionHeader(title: 'SMS engine · this week', action: 'SMS tools', onAction: () => onOpenTab?.call('sms')),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: DcnCard(
              onTap: () => onOpenTab?.call('sms'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$smsSent', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.text)),
                          Text('SMS logged this week', style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                        ],
                      ),
                      DcnChip(label: smsFailed == 0 ? 'All delivered' : '$smsFailed failed', tone: smsFailed == 0 ? DcnTone.success : DcnTone.danger, icon: smsFailed == 0 ? 'check' : 'alert'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentCard extends StatelessWidget {
  const _UrgentCard({required this.icon, required this.value, required this.label, required this.tone, required this.onTap});
  final String icon;
  final int value;
  final String label;
  final DcnTone tone;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = toneColors(context, tone);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.fg.withValues(alpha: 0.4))),
        child: Row(
          children: [
            DcnIcon(icon, size: 20, color: t.fg),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: t.fg)),
                  Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.fg)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PctBadge extends StatelessWidget {
  const _PctBadge({required this.pct});
  final int pct;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final color = pct >= 70 ? c.success : pct >= 40 ? c.warning : c.danger;
    return SizedBox(
      width: 56,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$pct%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: pct / 100, minHeight: 4, backgroundColor: c.surface2, valueColor: AlwaysStoppedAnimation(color)),
          ),
        ],
      ),
    );
  }
}
