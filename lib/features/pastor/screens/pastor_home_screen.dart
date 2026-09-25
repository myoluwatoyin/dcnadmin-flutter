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
import '../../hod/widgets/hod_widgets.dart';
import '../../worker/data/worker_providers.dart';
import '../../worker/widgets/worker_rows.dart';
import '../data/pastor_providers.dart';

class PastorHomeScreen extends ConsumerWidget {
  const PastorHomeScreen({super.key, this.onOpenTab});
  final void Function(String tabId)? onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final user = ref.watch(authStateProvider).valueOrNull;
    final stats = ref.watch(pastorStatsProvider);
    final depts = ref.watch(deptHealthProvider);
    final apps = ref.watch(pastorApplicationsProvider).valueOrNull ?? const [];
    final analytics = ref.watch(analyticsProvider).valueOrNull ?? const {};
    final unread = ref.watch(workerUnreadCountProvider);

    final sunAvg = (analytics['attendance_sunday_avg'] ?? 0) as int;
    final tueAvg = (analytics['attendance_tuesday_avg'] ?? 0) as int;
    final trend = (analytics['attendance_trend'] ?? '') as String;

    Widget header(bool scrolled) => DcnHeaderBar(
          scrolled: scrolled,
          left: Padding(padding: const EdgeInsets.only(right: 4), child: DcnAvatar(name: user?.fullName ?? '?', size: 36)),
          title: "Pastor's view",
          sub: '${stats.members} members · ${stats.workers} workers',
          right: [
            HeaderIconButton(icon: 'msg', dot: ref.watch(chatUnreadCountProvider) > 0, onTap: () => context.push('/chat')),
            const SizedBox(width: 6),
            HeaderIconButton(icon: 'bell', dot: unread > 0, onTap: () => onOpenTab?.call('alerts')),
          ],
        );

    return DcnScrollScaffold(
      header: header,
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendance hero → analytics
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: GestureDetector(
              onTap: () => context.push('/p/attendance'),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SUNDAY ATTENDANCE TREND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.85), letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Text('$sunAvg%', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
                              if (trim(trend).isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: const Color(0xFF34D399).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(999)),
                                  child: Row(children: [
                                    const DcnIcon('trending', size: 12, color: Colors.white),
                                    const SizedBox(width: 3),
                                    Text(trend, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ]),
                                ),
                              ],
                            ]),
                          ],
                        ),
                        DcnIcon('trending', size: 42, color: Colors.white.withValues(alpha: 0.4)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(padding: const EdgeInsets.only(top: 16), decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.18)))),
                      child: Row(children: [
                        _heroStat('TUESDAY', '$tueAvg%'),
                        const SizedBox(width: 24),
                        _heroStat('FIRST-TIMERS', '${stats.firstTimers}'),
                        const SizedBox(width: 24),
                        _heroStat('REPORTS', '${stats.reportsPct}%'),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Dept health
          DcnSectionHeader(title: '6 Departments · health', action: 'See all', onAction: () => onOpenTab?.call('departments')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DcnCard(
              child: Column(
                children: [
                  for (var i = 0; i < depts.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _DeptRow(d: depts[i], onTap: () => context.push('/p/dept/${depts[i].code}')),
                  ],
                ],
              ),
            ),
          ),
          // Quick actions
          const DcnSectionHeader(title: "Pastor's tools"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              Row(children: [
                Expanded(child: QuickAction(icon: 'user', label: 'Approvals', sub: '${apps.length} across depts', tone: DcnTone.warning, onTap: () => context.push('/p/approvals'))),
                const SizedBox(width: 10),
                Expanded(child: QuickAction(icon: 'user', label: 'Assign follow-up', sub: 'Any worker · cross-dept', tone: DcnTone.brand, onTap: () => context.push('/fh/assign'))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: QuickAction(icon: 'lock', label: 'Access keys', sub: 'Invite codes', tone: DcnTone.info, onTap: () => context.push('/p/access-keys'))),
                const SizedBox(width: 10),
                Expanded(child: QuickAction(icon: 'send', label: 'SMS blast', sub: 'Any segment', tone: DcnTone.success, onTap: () => context.push('/fh/sms-blast'))),
              ]),
            ]),
          ),
          // At a glance
          const DcnSectionHeader(title: 'At a glance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(child: DcnStatTile(label: 'Workers', value: '${stats.workers}', sub: '${stats.hods} HODs', icon: 'users', tone: DcnTone.brand, onTap: () => onOpenTab?.call('people'))),
              const SizedBox(width: 8),
              Expanded(child: DcnStatTile(label: 'At risk', value: '${stats.atRisk}', sub: '${stats.unreachable} unreach.', icon: 'alert', tone: DcnTone.warning, onTap: () => context.push('/fh/absence'))),
              const SizedBox(width: 8),
              Expanded(child: DcnStatTile(label: 'Scorecards', value: '${stats.scorecardsDone}/${stats.scorecardsTotal}', sub: 'Q2 done', icon: 'award', tone: DcnTone.info, onTap: () => context.push('/p/scorecards'))),
            ]),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static String trim(String s) => s.trim();

  Widget _heroStat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      );
}

class _DeptRow extends StatelessWidget {
  const _DeptRow({required this.d, required this.onTap});
  final DeptHealth d;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final tone = d.health == 'GOOD' ? DcnTone.success : d.health == 'WATCH' ? DcnTone.warning : DcnTone.danger;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: d.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: Text(d.name[0], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: d.color))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(d.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
                    Text('${d.workers}w · ${d.reportsPct}%', style: TextStyle(fontSize: 11, color: c.textMuted)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: d.reportsPct / 100, minHeight: 4, backgroundColor: c.surface2, valueColor: AlwaysStoppedAnimation(d.color))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          DcnChip(label: d.health == 'GOOD' ? 'Good' : d.health == 'WATCH' ? 'Watch' : 'Risk', tone: tone, size: DcnButtonSize.sm),
        ],
      ),
    );
  }
}
