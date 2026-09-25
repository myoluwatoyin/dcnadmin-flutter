import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_scroll_scaffold.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../hod/data/hod_providers.dart';
import '../../worker/data/worker_providers.dart';

class FuHodMoreScreen extends ConsumerWidget {
  const FuHodMoreScreen({super.key, this.onOpenTab});
  final void Function(String tabId)? onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final user = ref.watch(authStateProvider).valueOrNull;
    final apps = ref.watch(hodApplicationsProvider).valueOrNull ?? const [];
    final unread = ref.watch(workerUnreadCountProvider);

    Widget header(bool scrolled) => DcnHeaderBar(scrolled: scrolled, title: 'More');

    return DcnScrollScaffold(
      header: header,
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DcnCard(
              onTap: () => context.push('/profile'),
              child: Row(
                children: [
                  DcnAvatar(name: user?.fullName ?? '?', size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? 'FU HOD', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.text)),
                        const SizedBox(height: 2),
                        Text('HOD · Follow-Up', style: TextStyle(fontSize: 12.5, color: c.textMuted)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, children: [
                          const DcnChip(label: 'HOD', tone: DcnTone.brand, size: DcnButtonSize.sm, icon: 'star'),
                          if ((user?.memberId ?? '').isNotEmpty) DcnChip(label: user!.memberId, tone: DcnTone.neutral, size: DcnButtonSize.sm),
                        ]),
                      ],
                    ),
                  ),
                  DcnIcon('chevronRight', size: 20, color: c.textDim),
                ],
              ),
            ),
          ),
          _Group(title: 'Team management', rows: [
            (icon: 'user', title: 'Assign follow-up', sub: 'Members → workers', onTap: () => context.push('/fh/assign')),
            (icon: 'award', title: 'Q2 Scorecards', sub: 'Assess FU workers', onTap: () => context.push('/hod/scorecards')),
            (icon: 'bookOpen', title: 'Accountability board', sub: 'Bible & prayer', onTap: () => context.push('/hod/accountability')),
            (icon: 'user', title: 'Approvals', sub: '${apps.length} pending', onTap: () => context.push('/hod/approvals')),
            (icon: 'users', title: 'FU workers', sub: 'Performance board', onTap: () => onOpenTab?.call('workers')),
          ]),
          _Group(title: 'Follow-up tools', rows: [
            (icon: 'plus', title: 'Add member', sub: 'Manual · bulk · sync', onTap: () => context.push('/fu/add-member')),
            (icon: 'users', title: 'All members', sub: null, onTap: () => onOpenTab?.call('members')),
            (icon: 'star', title: 'First-timer pipeline', sub: null, onTap: () => context.push('/fu/first-timers')),
            (icon: 'cake', title: 'Birthday manager', sub: null, onTap: () => context.push('/fu/birthdays')),
            (icon: 'alert', title: 'Absence escalation', sub: null, onTap: () => context.push('/fh/absence')),
            (icon: 'phone', title: 'Unreachable list', sub: null, onTap: () => context.push('/fh/unreachable')),
          ]),
          _Group(title: 'SMS engine', rows: [
            (icon: 'settings', title: 'Absence rules', sub: 'Thresholds & templates', onTap: () => context.push('/fh/sms-rules')),
            (icon: 'bookOpen', title: 'All templates', sub: null, onTap: () => context.push('/fh/sms-templates')),
            (icon: 'send', title: 'Bulk blast', sub: 'Send to a segment', onTap: () => context.push('/fh/sms-blast')),
            (icon: 'list', title: 'SMS log', sub: null, onTap: () => context.push('/fh/sms-log')),
          ]),
          _Group(title: 'Account', rows: [
            (icon: 'user', title: 'Profile', sub: null, onTap: () => context.push('/profile')),
            (icon: 'bell', title: 'Notifications', sub: unread > 0 ? '$unread unread' : 'All caught up', onTap: () => context.push('/notifications')),
            (icon: 'settings', title: 'Settings', sub: null, onTap: () => context.push('/settings')),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: DcnButton(label: 'Sign out', variant: DcnButtonVariant.plain, icon: 'logout', full: true, onPressed: () => ref.read(authRepositoryProvider).signOut()),
          ),
          Center(child: Text('DCN Admin v1.0.0 · For ministry staff only.', style: TextStyle(fontSize: 11, color: c.textDim))),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows});
  final String title;
  final List<({String icon, String title, String? sub, VoidCallback onTap})> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DcnSectionHeader(title: title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DcnCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  Container(
                    decoration: BoxDecoration(border: i == rows.length - 1 ? null : Border(bottom: BorderSide(color: c.divider))),
                    child: InkWell(
                      onTap: rows[i].onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(10)), child: DcnIcon(rows[i].icon, size: 18, color: c.brand)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(rows[i].title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
                                  if (rows[i].sub != null) ...[const SizedBox(height: 2), Text(rows[i].sub!, style: TextStyle(fontSize: 12, color: c.textMuted))],
                                ],
                              ),
                            ),
                            DcnIcon('chevronRight', size: 18, color: c.textDim),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
