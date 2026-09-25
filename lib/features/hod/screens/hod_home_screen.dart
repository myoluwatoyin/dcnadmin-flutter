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
import '../../../models/meeting.dart';
import '../../../models/scorecard.dart';
import '../../../models/team_worker.dart';
import '../../worker/data/worker_providers.dart';
import '../../worker/widgets/worker_rows.dart';
import '../data/hod_providers.dart';
import '../widgets/hod_widgets.dart';

/// HOD dashboard: review-queue hero, quick actions, department health, the
/// accountability snapshot, next meeting, and at-risk workers.
class HodHomeScreen extends ConsumerWidget {
  const HodHomeScreen({super.key, this.onOpenTab});
  final void Function(String tabId)? onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final user = ref.watch(authStateProvider).valueOrNull;
    final team = ref.watch(hodTeamProvider).valueOrNull ?? const <TeamWorker>[];
    final review = ref.watch(hodReviewQueueProvider);
    final meetings = ref.watch(hodMeetingsProvider).valueOrNull ?? const <Meeting>[];
    final apps = ref.watch(hodApplicationsProvider).valueOrNull ?? const [];
    final scorecards = ref.watch(hodScorecardsProvider).valueOrNull ?? const <Scorecard>[];
    final unread = ref.watch(workerUnreadCountProvider);

    final total = team.length;
    final atRisk = team.where((w) => w.atRisk).length;
    final bothReports = team.where((w) => w.bothReports).length;
    final someReports = team.where((w) => w.someReports).length;
    final reportsPct = total == 0 ? 0 : ((bothReports / total) * 100).round();
    final tasksOpen = team.fold<int>(0, (s, w) => s + w.tasksOpen);
    final tasksOverdue = team.fold<int>(0, (s, w) => s + w.tasksOverdue);
    final scDone = scorecards
        .where((s) => s.quarter == 'Q2' && s.year == 2026)
        .length;
    final scDue = (total - scDone).clamp(0, total);
    final upcoming = meetings
        .where((m) => m.status != MeetingStatus.cancelled)
        .toList();
    final nextMeeting = upcoming.isNotEmpty ? upcoming.first : null;
    final atRiskWorkers = team.where((w) => w.atRisk).toList();

    Widget header(bool scrolled) => DcnHeaderBar(
          scrolled: scrolled,
          left: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: DcnAvatar(name: user?.fullName ?? '?', size: 36),
          ),
          title: '${user?.departmentName ?? 'Dept'} HOD',
          sub: '${user?.fullName ?? ''} · $total workers',
          right: [
            HeaderIconButton(icon: 'msg', dot: ref.watch(chatUnreadCountProvider) > 0, onTap: () => context.push('/chat')),
            const SizedBox(width: 6),
            HeaderIconButton(
                icon: 'bell', dot: unread > 0, onTap: () => context.push('/notifications')),
          ],
        );

    return DcnScrollScaffold(
      header: header,
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Review hero
          if (review.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GestureDetector(
                onTap: () => onOpenTab?.call('tasks'),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [c.brand, c.brandDeep],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AWAITING YOUR REVIEW',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text('${review.length}',
                                    style: const TextStyle(
                                        fontSize: 44,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1)),
                                const SizedBox(width: 6),
                                Text('tasks',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.85))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Submitted by your team — tap to review',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
                          ],
                        ),
                      ),
                      DcnIcon('clipboard', size: 42, color: Colors.white.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),
            ),

          // Quick actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: QuickAction(icon: 'plus', label: 'Assign task', sub: 'To worker or sub-unit', tone: DcnTone.brand, onTap: () => context.push('/hod/assign'))),
                    const SizedBox(width: 10),
                    Expanded(child: QuickAction(icon: 'calendar', label: 'New meeting', sub: 'One-off or recurring', tone: DcnTone.info, onTap: () => context.push('/hod/new-meeting'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: QuickAction(icon: 'award', label: 'Q2 scorecards', sub: '$scDue due', tone: DcnTone.warning, onTap: () => context.push('/hod/scorecards'))),
                    const SizedBox(width: 10),
                    Expanded(child: QuickAction(icon: 'user', label: 'Approvals', sub: '${apps.length} pending', tone: DcnTone.success, onTap: () => context.push('/hod/approvals'))),
                  ],
                ),
              ],
            ),
          ),

          // Department health
          const DcnSectionHeader(title: 'Department health'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: DcnStatTile(label: 'Active', value: '$someReports/$total', sub: 'this week', icon: 'users', tone: DcnTone.success, onTap: () => onOpenTab?.call('team'))),
                  const SizedBox(width: 8),
                  Expanded(child: DcnStatTile(label: 'At risk', value: '$atRisk', sub: 'need attention', icon: 'alert', tone: DcnTone.danger, onTap: () => onOpenTab?.call('team'))),
                  const SizedBox(width: 8),
                  Expanded(child: DcnStatTile(label: 'Reports in', value: '$reportsPct%', sub: 'Bible & prayer', icon: 'bookOpen', tone: DcnTone.brand, onTap: () => context.push('/hod/accountability'))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: DcnStatTile(label: 'Tasks open', value: '$tasksOpen', sub: tasksOverdue > 0 ? '$tasksOverdue overdue' : 'on track', icon: 'clipboard', tone: tasksOverdue > 0 ? DcnTone.warning : DcnTone.brand, onTap: () => onOpenTab?.call('tasks'))),
                  const SizedBox(width: 8),
                  Expanded(child: DcnStatTile(label: 'Scorecards', value: '$scDone/$total', sub: 'done', icon: 'award', tone: DcnTone.info, onTap: () => context.push('/hod/scorecards'))),
                  const SizedBox(width: 8),
                  Expanded(child: DcnStatTile(label: 'Meetings', value: '${upcoming.length}', sub: 'upcoming', icon: 'calendar', tone: DcnTone.brand, onTap: () => onOpenTab?.call('meetings'))),
                ]),
              ],
            ),
          ),

          // Accountability snapshot
          DcnSectionHeader(
            title: 'Accountability board',
            action: 'Full board',
            onAction: () => context.push('/hod/accountability'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DcnCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bible & prayer reports this week',
                          style: TextStyle(fontSize: 12.5, color: c.textMuted)),
                      Text('$bothReports/$total',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.text)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final w in team) _AccountabilityDot(worker: w),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Next meeting
          if (nextMeeting != null) ...[
            DcnSectionHeader(title: 'Next meeting', action: 'Calendar', onAction: () => onOpenTab?.call('meetings')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MeetingRow(meeting: nextMeeting, onTap: () => context.push('/hod/meeting/${nextMeeting.id}')),
            ),
          ],

          // At-risk workers
          if (atRiskWorkers.isNotEmpty) ...[
            DcnSectionHeader(title: 'Workers needing attention', action: 'See team', onAction: () => onOpenTab?.call('team')),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  for (final w in atRiskWorkers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DcnCard(
                        onTap: () => context.push('/hod/worker/${w.uid}'),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            DcnAvatar(name: w.name, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(w.name,
                                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text)),
                                  Text('${w.subUnit} · ${w.attendanceRate}% · last score ${w.scorecardLast}',
                                      style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                                ],
                              ),
                            ),
                            const DcnChip(label: 'At risk', tone: DcnTone.danger, size: DcnButtonSize.sm, icon: 'alert'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountabilityDot extends StatelessWidget {
  const _AccountabilityDot({required this.worker});
  final TeamWorker worker;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final both = worker.bothReports;
    final some = worker.someReports;
    final initials = worker.name
        .split(RegExp(r'\s+'))
        .map((s) => s.isNotEmpty ? s[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: both ? c.success : (some ? c.warning : c.dangerSoft),
        border: both || some ? null : Border.all(color: c.danger, width: 1.5),
      ),
      child: both
          ? const Icon(Icons.check, size: 12, color: Colors.white)
          : Text(initials,
              style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: some ? Colors.white : c.danger)),
    );
  }
}
