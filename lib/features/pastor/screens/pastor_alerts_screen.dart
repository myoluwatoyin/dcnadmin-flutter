import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/app_notification.dart';
import '../../worker/data/worker_providers.dart';

/// Pastor Alerts tab — church-wide notifications (uid-scoped to the pastor).
class PastorAlertsScreen extends ConsumerWidget {
  const PastorAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final async = ref.watch(workerNotificationsProvider);
    final all = async.valueOrNull ?? const <AppNotification>[];
    final unreadIds = all.where((n) => !n.read).map((n) => n.id).toList();

    return Column(
      children: [
        DcnHeaderBar(
          title: 'Alerts',
          sub: unreadIds.isEmpty ? 'All caught up' : '${unreadIds.length} unread',
          right: [
            if (unreadIds.isNotEmpty)
              GestureDetector(
                onTap: () => ref.read(workerRepositoryProvider).markAllNotificationsRead(unreadIds),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(999)),
                  child: Text('Mark all read', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.brandInk)),
                ),
              ),
          ],
        ),
        Expanded(
          child: async.isLoading && !async.hasValue
              ? const Center(child: CircularProgressIndicator())
              : all.isEmpty
                  ? const DcnEmptyState(icon: 'bell', title: 'All caught up', body: 'No alerts right now.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: all.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final n = all[i];
                        final tappable = (n.route ?? '').isNotEmpty;
                        return DcnCard(
                          onTap: tappable
                              ? () {
                                  if (!n.read) ref.read(workerRepositoryProvider).markNotificationRead(n.id);
                                  context.push(n.route!);
                                }
                              : (!n.read ? () => ref.read(workerRepositoryProvider).markNotificationRead(n.id) : null),
                          padding: const EdgeInsets.all(14),
                          child: Opacity(
                            opacity: n.read ? 0.72 : 1,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: n.urgent ? c.dangerSoft : c.brandSoft, borderRadius: BorderRadius.circular(10)), child: DcnIcon(n.urgent ? 'alert' : 'bell', size: 18, color: n.urgent ? c.danger : c.brand)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(child: Text(n.title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text))),
                                        if (!n.read) Container(width: 8, height: 8, margin: const EdgeInsets.only(left: 6, top: 4), decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle)),
                                      ]),
                                      const SizedBox(height: 2),
                                      Text(n.body, style: TextStyle(fontSize: 12.5, color: c.textMuted, height: 1.45)),
                                      if (n.at.isNotEmpty) ...[const SizedBox(height: 4), Text(n.at, style: TextStyle(fontSize: 11, color: c.textDim))],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
