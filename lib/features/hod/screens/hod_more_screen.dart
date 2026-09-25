import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_scroll_scaffold.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../worker/data/worker_providers.dart';
import '../data/hod_providers.dart';

class HodMoreScreen extends ConsumerWidget {
  const HodMoreScreen({super.key});

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
                        Text(user?.fullName ?? 'HOD', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.text)),
                        const SizedBox(height: 2),
                        Text('HOD · ${user?.departmentName ?? ''}', style: TextStyle(fontSize: 12.5, color: c.textMuted)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, children: [
                          const DcnChip(label: 'HOD', tone: DcnTone.brand, size: DcnButtonSize.sm, icon: 'star'),
                          if ((user?.memberId ?? '').isNotEmpty)
                            DcnChip(label: user!.memberId, tone: DcnTone.neutral, size: DcnButtonSize.sm),
                        ]),
                      ],
                    ),
                  ),
                  DcnIcon('chevronRight', size: 20, color: c.textDim),
                ],
              ),
            ),
          ),
          _Group(title: 'HOD tools', rows: [
            (icon: 'award', title: 'Q2 Scorecards', sub: 'Assess your team', onTap: () => context.push('/hod/scorecards')),
            (icon: 'user', title: 'Approvals', sub: '${apps.length} pending', onTap: () => context.push('/hod/approvals')),
            (icon: 'grid', title: 'Sub-units', sub: null, onTap: () => context.push('/hod/subunits')),
            (icon: 'bookOpen', title: 'Accountability board', sub: null, onTap: () => context.push('/hod/accountability')),
            (icon: 'sparkle', title: 'Life updates inbox', sub: 'From your team', onTap: () => context.push('/hod/life-inbox')),
            (icon: 'send', title: 'Send dept-wide message', sub: null, onTap: () => context.push('/hod/blast')),
          ]),
          _Group(title: 'Account', rows: [
            (icon: 'user', title: 'Profile', sub: null, onTap: () => context.push('/profile')),
            (icon: 'bell', title: 'Notifications', sub: unread > 0 ? '$unread unread' : 'All caught up', onTap: () => context.push('/notifications')),
            (icon: 'settings', title: 'Settings', sub: null, onTap: () => context.push('/settings')),
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
                    decoration: BoxDecoration(
                      border: i == rows.length - 1 ? null : Border(bottom: BorderSide(color: c.divider)),
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
                              decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(10)),
                              child: DcnIcon(rows[i].icon, size: 18, color: c.brand),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(rows[i].title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
                                  if (rows[i].sub != null) ...[
                                    const SizedBox(height: 2),
                                    Text(rows[i].sub!, style: TextStyle(fontSize: 12, color: c.textMuted)),
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
