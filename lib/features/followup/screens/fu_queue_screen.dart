import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/member.dart';
import '../data/fu_providers.dart';
import '../widgets/fu_widgets.dart';

class FuQueueScreen extends ConsumerStatefulWidget {
  const FuQueueScreen({super.key});
  @override
  ConsumerState<FuQueueScreen> createState() => _State();
}

class _State extends ConsumerState<FuQueueScreen> {
  String _tab = 'PENDING';

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final queue = ref.watch(fuQueueProvider);
    final pending = queue.where((m) => !m.queueDone).length;
    final done = queue.where((m) => m.queueDone).length;
    final items = queue.where((m) {
      if (_tab == 'ALL') return true;
      if (_tab == 'PENDING') return !m.queueDone;
      return m.queueDone;
    }).toList();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Follow-up queue', sub: 'This week', onBack: () => context.pop()),
            Container(
              color: c.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: DcnSegmented(
                options: [
                  (id: 'PENDING', label: 'To do ($pending)'),
                  (id: 'DONE', label: 'Done ($done)'),
                  (id: 'ALL', label: 'All'),
                ],
                value: _tab,
                onChanged: (v) => setState(() => _tab = v),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const DcnEmptyState(icon: 'checkCircle', title: 'All done for this week', body: 'Come back Monday for the new queue.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _QueueRow(m: items[i], onTap: () => context.push('/fu/member/${items[i].id}')),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.m, required this.onTap});
  final Member m;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return DcnCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          DcnAvatar(name: m.name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(m.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text))),
                    const SizedBox(width: 6),
                    DcnChip(label: priorityLabel(m.queuePriority), tone: priorityTone(m.queuePriority), size: DcnButtonSize.sm),
                  ],
                ),
                const SizedBox(height: 3),
                Text(m.queueReason, style: TextStyle(fontSize: 12, color: c.textMuted)),
                if (m.queueDone && m.lastOutcome.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('✓ ${m.lastOutcome}', style: TextStyle(fontSize: 11.5, color: c.success, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          m.queueDone
              ? DcnIcon('checkCircle', size: 20, color: c.success)
              : DcnIcon('chevronRight', size: 18, color: c.textDim),
        ],
      ),
    );
  }
}
