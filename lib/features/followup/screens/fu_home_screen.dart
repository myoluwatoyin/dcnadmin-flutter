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
import '../../hod/widgets/hod_widgets.dart';
import '../../worker/data/worker_providers.dart';
import '../../worker/widgets/worker_rows.dart';
import '../data/fu_providers.dart';
import '../widgets/fu_widgets.dart';

class FuHomeScreen extends ConsumerWidget {
  const FuHomeScreen({super.key, this.onOpenTab});
  final void Function(String tabId)? onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final user = ref.watch(authStateProvider).valueOrNull;
    final members = ref.watch(fuMembersProvider).valueOrNull ?? const <Member>[];
    final queue = ref.watch(fuQueueProvider);
    final birthdays = ref.watch(fuBirthdaysProvider);
    final firstTimers = ref.watch(fuFirstTimersProvider);
    final unread = ref.watch(workerUnreadCountProvider);

    final pending = queue.where((m) => !m.queueDone).toList();
    final done = queue.where((m) => m.queueDone).length;
    final urgent = pending.where((m) => m.queuePriority == 'urgent').length;
    final atRisk = members.where((m) => m.isAtRisk).length;
    final unreachable = members.where((m) => m.unreachable).length;
    final todayBdays = birthdays.where((m) => m.nextBirthdayLabel == 'Today').toList();

    Widget header(bool scrolled) => DcnHeaderBar(
          scrolled: scrolled,
          left: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: DcnAvatar(name: user?.fullName ?? '?', size: 36),
          ),
          title: 'Hi, ${(user?.firstName ?? '').isNotEmpty ? user!.firstName! : 'there'}',
          sub: [user?.departmentName, user?.subUnitName].where((s) => (s ?? '').isNotEmpty).join(' · '),
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
          // Queue hero
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: GestureDetector(
              onTap: () => context.push('/fu/queue'),
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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("THIS WEEK'S FOLLOW-UPS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.85), letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('${pending.length}', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
                                  const SizedBox(width: 6),
                                  Text('to do · $done done', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        DcnIcon('users', size: 42, color: Colors.white.withValues(alpha: 0.5)),
                      ],
                    ),
                    if (urgent > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const DcnIcon('alert', size: 14, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('$urgent urgent — call today', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
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
                Row(children: [
                  Expanded(child: QuickAction(icon: 'checkCircle', label: 'Take attendance', sub: 'Sunday service', tone: DcnTone.brand, onTap: () => context.push('/fu/attendance/SUNDAY'))),
                  const SizedBox(width: 10),
                  Expanded(child: QuickAction(icon: 'cake', label: 'Birthdays', sub: '${birthdays.length} this week', tone: DcnTone.warning, onTap: () => context.push('/fu/birthdays'))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: QuickAction(icon: 'star', label: 'First-timers', sub: '${firstTimers.length} in pipeline', tone: DcnTone.info, onTap: () => context.push('/fu/first-timers'))),
                  const SizedBox(width: 10),
                  Expanded(child: QuickAction(icon: 'plus', label: 'Add member', sub: 'Manual · bulk · sync', tone: DcnTone.success, onTap: () => context.push('/fu/add-member'))),
                ]),
              ],
            ),
          ),
          // Stats
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(child: DcnStatTile(label: 'At risk', value: '$atRisk', icon: 'alert', tone: DcnTone.warning, onTap: () => onOpenTab?.call('members'))),
              const SizedBox(width: 8),
              Expanded(child: DcnStatTile(label: 'Unreachable', value: '$unreachable', icon: 'phone', tone: DcnTone.danger, onTap: () => onOpenTab?.call('members'))),
              const SizedBox(width: 8),
              Expanded(child: DcnStatTile(label: 'My members', value: '${members.length}', icon: 'users', tone: DcnTone.brand, onTap: () => onOpenTab?.call('members'))),
            ]),
          ),
          if (todayBdays.isNotEmpty) ...[
            DcnSectionHeader(title: '🎂 Today’s birthday', action: 'View all', onAction: () => context.push('/fu/birthdays')),
            for (final b in todayBdays)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DcnCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      DcnAvatar(name: b.name, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                            Text('SMS sent 7:00 AM — call to wish personally', style: TextStyle(fontSize: 12, color: c.textMuted)),
                          ],
                        ),
                      ),
                      DcnButton(label: 'Call', size: DcnButtonSize.sm, icon: 'phone', onPressed: () {}),
                    ],
                  ),
                ),
              ),
          ],
          // Pending queue preview
          if (pending.isNotEmpty) ...[
            DcnSectionHeader(title: 'Up next in your queue', action: 'Full queue', onAction: () => context.push('/fu/queue')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final m in pending.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DcnCard(
                        onTap: () => context.push('/fu/member/${m.id}'),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            DcnAvatar(name: m.name, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text)),
                                  Text(m.queueReason, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.textMuted)),
                                ],
                              ),
                            ),
                            DcnChip(label: priorityLabel(m.queuePriority), tone: priorityTone(m.queuePriority), size: DcnButtonSize.sm),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const DcnSectionHeader(title: 'Recent activity'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: const [
                ActivityItem(icon: 'phone', tone: DcnTone.success, title: 'Logged a call outcome', sub: 'This week'),
                ActivityItem(icon: 'cake', tone: DcnTone.warning, title: 'Birthday SMS sent', sub: 'Today · 7:00 AM'),
                ActivityItem(icon: 'user', tone: DcnTone.brand, title: 'New first-timers assigned', sub: 'Sunday'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
