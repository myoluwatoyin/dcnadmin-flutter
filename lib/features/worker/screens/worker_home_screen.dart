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
import '../../../models/followup_assignment.dart';
import '../../../models/meeting.dart';
import '../../../models/task.dart';
import '../../../models/weekly_report.dart';
import '../data/worker_providers.dart';
import '../widgets/worker_rows.dart';

/// Worker dashboard, ported 1:1 from the prototype and wired to live Firestore
/// data. Sections appear only when they have real content; loading shows a
/// skeleton, and the report hero reflects the actual weekly-report state.
class WorkerHomeScreen extends ConsumerWidget {
  const WorkerHomeScreen({super.key, this.onOpenTab});

  /// Lets Home jump the shell to another tab (report/tasks/schedule).
  final void Function(String tabId)? onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final user = ref.watch(authStateProvider).valueOrNull;
    final tasksA = ref.watch(workerTasksProvider);
    final meetingsA = ref.watch(workerMeetingsProvider);
    final reportsA = ref.watch(workerReportsProvider);
    final followupsA = ref.watch(workerFollowupsProvider);
    final unread = ref.watch(workerUnreadCountProvider);

    final firstName = (user?.firstName ?? '').isNotEmpty ? user!.firstName! : 'there';
    final deptSub = [user?.departmentName, user?.subUnitName]
        .where((s) => (s ?? '').isNotEmpty)
        .join(' · ');

    Widget header(bool scrolled) => DcnHeaderBar(
          scrolled: scrolled,
          left: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: DcnAvatar(name: user?.fullName ?? '?', size: 36, photoUrl: user?.photoUrl),
          ),
          title: 'Hi, $firstName',
          sub: deptSub.isNotEmpty ? deptSub : null,
          right: [
            HeaderIconButton(icon: 'msg', dot: ref.watch(chatUnreadCountProvider) > 0, onTap: () => context.push('/chat')),
            const SizedBox(width: 6),
            HeaderIconButton(
              icon: 'bell',
              dot: unread > 0,
              onTap: () => context.push('/notifications'),
            ),
          ],
        );

    final loading = tasksA.isLoading || reportsA.isLoading;
    if (loading && !tasksA.hasValue) {
      return DcnScrollScaffold(
        header: header,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: const _HomeSkeleton(),
      );
    }

    final tasks = tasksA.valueOrNull ?? const <Task>[];
    final meetings = meetingsA.valueOrNull ?? const <Meeting>[];
    final reports = reportsA.valueOrNull ?? const <WeeklyReport>[];
    final followups = followupsA.valueOrNull ?? const <FollowupAssignment>[];

    final active = tasks.where((t) => t.isActive).toList();
    final completed = tasks.where((t) => t.status == TaskStatus.approved).length;
    final overdue = tasks.where((t) => t.status == TaskStatus.overdue).length;
    final streak = _bibleStreak(reports);
    final reportDue = reports.isEmpty || !reports.first.submitted;
    final pendingFollowups =
        followups.where((f) => f.status == FollowupStatus.pending).toList();
    final nextMeeting = meetings.isNotEmpty ? meetings.first : null;

    return DcnScrollScaffold(
      header: header,
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reportDue)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _ReportHero(streak: streak, onTap: () => onOpenTab?.call('report')),
            ),
          // 4 stat tiles
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: DcnStatTile(
                    label: 'Completed',
                    value: '$completed',
                    sub: 'this month',
                    icon: 'checkCircle',
                    tone: DcnTone.success,
                    onTap: () => onOpenTab?.call('tasks'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DcnStatTile(
                    label: 'Active tasks',
                    value: '${active.length}',
                    sub: overdue > 0 ? '$overdue overdue' : 'All on track',
                    icon: 'clock',
                    tone: overdue > 0 ? DcnTone.danger : DcnTone.warning,
                    onTap: () => onOpenTab?.call('tasks'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DcnStatTile(
                    label: 'Bible streak',
                    value: '${streak}w',
                    sub: 'Keep going',
                    icon: 'flame',
                    tone: DcnTone.brand,
                    onTap: () => onOpenTab?.call('report'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DcnStatTile(
                    label: 'Next event',
                    value: nextMeeting != null ? _relativeDay(nextMeeting) : '—',
                    sub: nextMeeting?.start ?? 'Nothing soon',
                    icon: 'calendar',
                    tone: DcnTone.info,
                    onTap: () => onOpenTab?.call('schedule'),
                  ),
                ),
              ],
            ),
          ),

          if (pendingFollowups.isNotEmpty) ...[
            DcnSectionHeader(
              title: 'Follow-ups assigned to you',
              action: 'See all',
              onAction: () => context.push('/followups'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _FollowupCard(items: pendingFollowups),
            ),
          ],

          DcnSectionHeader(
            title: "Today's schedule",
            action: 'View all',
            onAction: () => onOpenTab?.call('schedule'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: meetings.isEmpty
                ? DcnCard(
                    padding: const EdgeInsets.all(14),
                    child: Text('Nothing scheduled.',
                        style: TextStyle(fontSize: 13, color: c.textMuted)),
                  )
                : Column(
                    children: [
                      for (final m in meetings.take(2))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: MeetingRow(
                            meeting: m,
                            compact: true,
                            onTap: () => context.push('/meeting/${m.id}'),
                          ),
                        ),
                    ],
                  ),
          ),

          if (active.isNotEmpty) ...[
            DcnSectionHeader(
              title: 'Up next',
              action: 'My tasks',
              onAction: () => onOpenTab?.call('tasks'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final t in active.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TaskRow(task: t, onTap: () => context.push('/task/${t.id}')),
                    ),
                ],
              ),
            ),
          ],

          ..._recentActivity(context, tasks, meetings, reports),
        ],
      ),
    );
  }

  static int _bibleStreak(List<WeeklyReport> reports) {
    // Reports are newest-first. Skip a leading still-open week (the current
    // one), then count the consecutive submitted run until the first gap.
    var n = 0;
    var seenSubmitted = false;
    for (final r in reports) {
      if (r.submitted) {
        n++;
        seenSubmitted = true;
      } else if (seenSubmitted) {
        break;
      }
    }
    return n;
  }

  static String _relativeDay(Meeting m) {
    final d = m.startAt;
    if (d == null) return m.date.isNotEmpty ? m.date.split(',').first : 'Soon';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.difference(today).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 7) return _weekday(d.weekday);
    return '${d.day}/${d.month}';
  }

  static String _weekday(int w) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][(w - 1) % 7];

  List<Widget> _recentActivity(
    BuildContext context,
    List<Task> tasks,
    List<Meeting> meetings,
    List<WeeklyReport> reports,
  ) {
    final items = <Widget>[];
    for (final t in tasks.where((t) => t.status == TaskStatus.approved).take(2)) {
      items.add(ActivityItem(
        icon: 'award',
        tone: DcnTone.success,
        title: 'Approved: ${t.title}',
        sub: t.dueDate.isNotEmpty ? t.dueDate : 'Recently',
      ));
    }
    for (final r in reports.where((r) => r.submitted).take(1)) {
      items.add(ActivityItem(
        icon: 'bookOpen',
        tone: DcnTone.brand,
        title: 'Bible report logged',
        sub: r.weekLabel,
      ));
    }
    for (final m in meetings.where((m) => m.status == MeetingStatus.rescheduled).take(1)) {
      items.add(ActivityItem(
        icon: 'calendar',
        tone: DcnTone.warning,
        title: '${m.title} rescheduled',
        sub: m.reason ?? m.date,
      ));
    }
    if (items.isEmpty) return const [];
    return [
      const DcnSectionHeader(title: 'Recent activity'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(children: items),
      ),
    ];
  }
}

class _ReportHero extends StatelessWidget {
  const _ReportHero({required this.streak, this.onTap});
  final int streak;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
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
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const DcnIcon('bookOpen', size: 26, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THIS WEEK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Submit your Bible & prayer report',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Due Thursday · Streak: $streak weeks',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const DcnIcon('chevronRight', size: 22, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _FollowupCard extends StatelessWidget {
  const _FollowupCard({required this.items});
  final List<FollowupAssignment> items;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.infoSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.info.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DcnIcon('users', size: 20, color: c.info),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${items.length} member${items.length == 1 ? '' : 's'} to check in on',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.info),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Assigned by the Follow-Up team — usually shared school or interest.',
                      style: TextStyle(fontSize: 11.5, color: c.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final f in items.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    DcnAvatar(name: f.memberName, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.memberName,
                              style: TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w700, color: c.text)),
                          Text(f.reason,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: c.textMuted)),
                        ],
                      ),
                    ),
                    DcnChip(
                      label: f.priority.label,
                      tone: switch (f.priority) {
                        FollowupPriority.urgent => DcnTone.danger,
                        FollowupPriority.high => DcnTone.warning,
                        _ => DcnTone.info,
                      },
                      size: DcnButtonSize.sm,
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

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    Widget box(double h, {double r = 16}) => Container(
          height: h,
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(r)),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        box(92, r: 18),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: box(110)),
          const SizedBox(width: 10),
          Expanded(child: box(110)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: box(110)),
          const SizedBox(width: 10),
          Expanded(child: box(110)),
        ]),
        const SizedBox(height: 20),
        box(70),
        const SizedBox(height: 8),
        box(70),
      ],
    );
  }
}
