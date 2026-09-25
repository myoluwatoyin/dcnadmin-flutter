import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_scroll_scaffold.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../data/worker_providers.dart';

/// Worker "More" menu: profile card + grouped rows wired to their screens.
class WorkerMoreScreen extends ConsumerWidget {
  const WorkerMoreScreen({super.key, this.onOpenTab});
  final void Function(String tabId)? onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final user = ref.watch(authStateProvider).valueOrNull;
    final unread = ref.watch(workerUnreadCountProvider);

    Widget header(bool scrolled) => DcnHeaderBar(scrolled: scrolled, title: 'More');

    return DcnScrollScaffold(
      header: header,
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DcnCard(
              onTap: () => context.push('/profile'),
              child: Row(
                children: [
                  DcnAvatar(name: user?.fullName ?? '?', size: 56, photoUrl: user?.photoUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName.isNotEmpty == true ? user!.fullName : 'Worker',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.text)),
                        const SizedBox(height: 2),
                        Text(
                          [user?.departmentName, user?.subUnitName]
                              .where((s) => (s ?? '').isNotEmpty)
                              .join(' · '),
                          style: TextStyle(fontSize: 12.5, color: c.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (user?.role != null)
                              DcnChip(label: user!.role!.wire, tone: DcnTone.brand, size: DcnButtonSize.sm),
                            if ((user?.memberId ?? '').isNotEmpty)
                              DcnChip(label: user!.memberId, tone: DcnTone.neutral, size: DcnButtonSize.sm),
                          ],
                        ),
                      ],
                    ),
                  ),
                  DcnIcon('chevronRight', size: 20, color: c.textDim),
                ],
              ),
            ),
          ),
          _Group(title: 'Ministry', rows: [
            (icon: 'users', title: 'Follow-ups assigned to me', sub: 'Cross-dept member check-ins', onTap: () => context.push('/followups')),
            (icon: 'award', title: 'Scorecards', sub: 'Your quarterly assessments', onTap: () => context.push('/scorecards')),
            (icon: 'users', title: 'Accountability partner', sub: 'Weekly check-in with a peer', onTap: () => context.push('/accountability')),
            (icon: 'sparkle', title: 'Life updates', sub: 'Share testimonies & prayer needs', onTap: () => context.push('/life')),
            (icon: 'bookOpen', title: 'All my reports', sub: 'Bible & prayer history', onTap: () => onOpenTab?.call('report')),
          ]),
          _Group(title: 'Account', rows: [
            (icon: 'user', title: 'Profile & access key', sub: null, onTap: () => context.push('/profile')),
            (icon: 'bell', title: 'Notifications', sub: unread > 0 ? '$unread unread' : 'All caught up', onTap: () => context.push('/notifications')),
            (icon: 'settings', title: 'Settings & preferences', sub: null, onTap: () => context.push('/settings')),
          ]),
          _Group(title: 'Support', rows: [
            (icon: 'msg', title: 'Contact your HOD', sub: null, onTap: () {}),
            (icon: 'alertCircle', title: 'Report a problem', sub: null, onTap: () {}),
            (icon: 'bookOpen', title: 'DCN ministry handbook', sub: null, onTap: () {}),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: DcnButton(
              label: 'Sign out',
              variant: DcnButtonVariant.plain,
              icon: 'logout',
              full: true,
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
            ),
          ),
          Center(
            child: Text('DCN Admin v1.0.0 · For ministry staff only.',
                style: TextStyle(fontSize: 11, color: c.textDim)),
          ),
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
                    decoration: BoxDecoration(
                      border: i == rows.length - 1
                          ? null
                          : Border(bottom: BorderSide(color: c.divider)),
                    ),
                    child: InkWell(
                      onTap: rows[i].onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.brandSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DcnIcon(rows[i].icon, size: 18, color: c.brand),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(rows[i].title,
                                      style: TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
                                  if (rows[i].sub != null) ...[
                                    const SizedBox(height: 2),
                                    Text(rows[i].sub!,
                                        style: TextStyle(fontSize: 12, color: c.textMuted)),
                                  ],
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
