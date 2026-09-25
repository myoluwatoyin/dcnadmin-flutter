import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_scroll_scaffold.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../data/pastor_providers.dart';

class PastorMoreScreen extends ConsumerWidget {
  const PastorMoreScreen({super.key, this.onOpenTab});
  final void Function(String tabId)? onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final user = ref.watch(authStateProvider).valueOrNull;
    final apps = ref.watch(pastorApplicationsProvider).valueOrNull ?? const [];

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
              child: Row(children: [
                DcnAvatar(name: user?.fullName ?? '?', size: 56),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.fullName ?? 'Pastor', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.text)),
                  const SizedBox(height: 2),
                  Text('Pastor · Super-Admin', style: TextStyle(fontSize: 12.5, color: c.textMuted)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, children: [
                    const DcnChip(label: 'PASTOR', tone: DcnTone.brand, size: DcnButtonSize.sm, icon: 'star'),
                    if ((user?.memberId ?? '').isNotEmpty) DcnChip(label: user!.memberId, tone: DcnTone.neutral, size: DcnButtonSize.sm),
                  ]),
                ])),
                DcnIcon('chevronRight', size: 20, color: c.textDim),
              ]),
            ),
          ),
          _Group(title: 'Oversight', rows: [
            (icon: 'user', title: 'Approvals', sub: '${apps.length} across depts', onTap: () => context.push('/p/approvals')),
            (icon: 'trending', title: 'Attendance analytics', sub: null, onTap: () => context.push('/p/attendance')),
            (icon: 'award', title: 'Scorecard analytics', sub: null, onTap: () => context.push('/p/scorecards')),
            (icon: 'users', title: 'Follow-up monitor', sub: 'Retention & cases', onTap: () => context.push('/p/followup')),
            (icon: 'send', title: 'SMS dashboard', sub: null, onTap: () => context.push('/p/sms')),
            (icon: 'sparkle', title: 'Life-updates inbox', sub: 'From all workers', onTap: () => context.push('/p/life')),
          ]),
          _Group(title: 'Ministry tools', rows: [
            (icon: 'user', title: 'Assign follow-up', sub: 'Any worker · cross-dept', onTap: () => context.push('/fh/assign')),
            (icon: 'plus', title: 'Add member', sub: null, onTap: () => context.push('/fu/add-member')),
            (icon: 'alert', title: 'Absence escalation', sub: null, onTap: () => context.push('/fh/absence')),
          ]),
          _Group(title: 'Administration', rows: [
            (icon: 'lock', title: 'Access keys', sub: 'Invite codes', onTap: () => context.push('/p/access-keys')),
            (icon: 'settings', title: 'System settings', sub: 'Church-wide config', onTap: () => context.push('/p/settings')),
          ]),
          _Group(title: 'Account', rows: [
            (icon: 'user', title: 'Profile', sub: null, onTap: () => context.push('/profile')),
            (icon: 'bell', title: 'Alerts', sub: null, onTap: () => onOpenTab?.call('alerts')),
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
                        child: Row(children: [
                          Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(10)), child: DcnIcon(rows[i].icon, size: 18, color: c.brand)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(rows[i].title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
                            if (rows[i].sub != null) ...[const SizedBox(height: 2), Text(rows[i].sub!, style: TextStyle(fontSize: 12, color: c.textMuted))],
                          ])),
                          DcnIcon('chevronRight', size: 18, color: c.textDim),
                        ]),
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
