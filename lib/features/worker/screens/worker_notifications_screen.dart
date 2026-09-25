import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_sheet.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/app_notification.dart';
import '../data/worker_providers.dart';

/// Notifications with All / Unread / Urgent filters, mark-all-read, clear-read,
/// deep-linking into detail screens, and the accountability partner-request
/// accept/deny sheet. Read state persists to Firestore.
class WorkerNotificationsScreen extends ConsumerStatefulWidget {
  const WorkerNotificationsScreen({super.key});

  @override
  ConsumerState<WorkerNotificationsScreen> createState() => _State();
}

class _State extends ConsumerState<WorkerNotificationsScreen> {
  String _filter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final async = ref.watch(workerNotificationsProvider);
    final all = async.valueOrNull ?? const <AppNotification>[];
    final unreadIds = all.where((n) => !n.read).map((n) => n.id).toList();
    final unread = unreadIds.length;

    final shown = all.where((n) {
      if (_filter == 'UNREAD') return !n.read;
      if (_filter == 'URGENT') return n.urgent;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(
              title: 'Notifications',
              sub: unread == 0 ? 'All caught up' : '$unread unread',
              onBack: () => context.pop(),
              right: [
                if (unread > 0)
                  GestureDetector(
                    onTap: () => ref
                        .read(workerRepositoryProvider)
                        .markAllNotificationsRead(unreadIds),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.brandSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('Mark all read',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: c.brandInk)),
                    ),
                  ),
              ],
            ),
            Container(
              color: c.surface,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: DcnSegmented(
                small: true,
                options: [
                  (id: 'ALL', label: 'All'),
                  (id: 'UNREAD', label: 'Unread ($unread)'),
                  (id: 'URGENT', label: 'Urgent'),
                ],
                value: _filter,
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
            Expanded(
              child: async.isLoading && !async.hasValue
                  ? const Center(child: CircularProgressIndicator())
                  : shown.isEmpty
                      ? const DcnEmptyState(
                          icon: 'bell',
                          title: 'All caught up',
                          body: 'No notifications match this filter.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: shown.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _NotifCard(
                            n: shown[i],
                            onTap: () => _onTap(shown[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(AppNotification n) {
    if (!n.read) {
      ref.read(workerRepositoryProvider).markNotificationRead(n.id);
    }
    if (n.isPartnerRequest) {
      _openPartnerSheet(n);
      return;
    }
    if ((n.route ?? '').isNotEmpty) {
      context.push(n.route!);
    }
  }

  Future<void> _openPartnerSheet(AppNotification n) async {
    await showDcnSheet<void>(
      context: context,
      title: 'Partner request',
      builder: (ctx) {
        final c = ctx.dcn;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DcnAvatar(name: n.partnerName ?? '?', size: 48),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.partnerName ?? '',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.text)),
                    if ((n.partnerSub ?? '').isNotEmpty)
                      Text(n.partnerSub!, style: TextStyle(fontSize: 12, color: c.textMuted)),
                  ],
                ),
              ],
            ),
            if ((n.partnerNote ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(12)),
                child: Text('"${n.partnerNote}"',
                    style: TextStyle(fontSize: 12.5, color: c.text, height: 1.5)),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              "Accountability partners check in weekly on Bible reading and prayer, and can see each other's streaks.",
              style: TextStyle(fontSize: 11.5, color: c.textDim, height: 1.5),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DcnButton(
                    label: 'Decline',
                    variant: DcnButtonVariant.ghost,
                    icon: 'x',
                    full: true,
                    onPressed: () => _decide(ctx, false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DcnButton(
                    label: 'Accept partner',
                    variant: DcnButtonVariant.success,
                    icon: 'check',
                    full: true,
                    onPressed: () => _decide(ctx, true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  void _decide(BuildContext sheetCtx, bool accepted) {
    Navigator.of(sheetCtx).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(accepted ? 'Partner request accepted 🤝' : 'Request declined'),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.n, required this.onTap});
  final AppNotification n;
  final VoidCallback onTap;

  ({String icon, DcnTone tone}) get _visual {
    if (n.urgent) return (icon: 'alert', tone: DcnTone.danger);
    return switch (n.type) {
      'MEETING_RESCHEDULED' => (icon: 'calendar', tone: DcnTone.warning),
      'MEETING_EMERGENCY' => (icon: 'alert', tone: DcnTone.danger),
      'MEETING_REMINDER' => (icon: 'calendar', tone: DcnTone.info),
      'TASK_OVERDUE' => (icon: 'clock', tone: DcnTone.danger),
      'TASK_ASSIGNED' => (icon: 'clipboard', tone: DcnTone.brand),
      'REPORT_REMINDER' => (icon: 'bookOpen', tone: DcnTone.brand),
      'SCORECARD_DUE' => (icon: 'award', tone: DcnTone.info),
      'PARTNER_REQUEST' => (icon: 'users', tone: DcnTone.brand),
      _ => (icon: 'bell', tone: DcnTone.brand),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final v = _visual;
    final tappable = n.isPartnerRequest || (n.route ?? '').isNotEmpty;
    final ({Color bg, Color fg}) t = switch (v.tone) {
      DcnTone.neutral => (bg: c.surface2, fg: c.textMuted),
      DcnTone.brand => (bg: c.brandSoft, fg: c.brand),
      DcnTone.success => (bg: c.successSoft, fg: c.success),
      DcnTone.warning => (bg: c.warningSoft, fg: c.warning),
      DcnTone.danger => (bg: c.dangerSoft, fg: c.danger),
      DcnTone.info => (bg: c.infoSoft, fg: c.info),
    };
    return Opacity(
      opacity: n.read ? 0.78 : 1,
      child: DcnCard(
        onTap: tappable ? onTap : null,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(10)),
              child: DcnIcon(v.icon, size: 18, color: t.fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(n.title,
                            style: TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text)),
                      ),
                      if (!n.read)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6, top: 4),
                          decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(n.body, style: TextStyle(fontSize: 12.5, color: c.textMuted, height: 1.45)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(n.at, style: TextStyle(fontSize: 11, color: c.textDim)),
                      if (tappable) ...[
                        const Spacer(),
                        Text(n.isPartnerRequest ? 'Review' : 'Open',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.brand)),
                        DcnIcon('chevronRight', size: 12, color: c.brand),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
