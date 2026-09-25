import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/task.dart';
import '../../worker/widgets/worker_rows.dart';
import '../data/hod_providers.dart';

class HodTasksScreen extends ConsumerStatefulWidget {
  const HodTasksScreen({super.key});
  @override
  ConsumerState<HodTasksScreen> createState() => _State();
}

class _State extends ConsumerState<HodTasksScreen> {
  String _tab = 'REVIEW';

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final tasks = ref.watch(hodDeptTasksProvider).valueOrNull ?? const <Task>[];
    final review = ref.watch(hodReviewQueueProvider);
    final open = tasks.where((t) => t.status != TaskStatus.approved).toList();
    final overdue = tasks.where((t) => t.status == TaskStatus.overdue).toList();

    final List<Widget> body;
    if (_tab == 'REVIEW') {
      body = review.isEmpty
          ? [const DcnEmptyState(icon: 'checkCircle', title: 'Nothing to review', body: 'No submitted tasks waiting on you.')]
          : [for (final t in review) _ReviewRow(task: t, onTap: () => context.push('/hod/review/${t.id}'))];
    } else if (_tab == 'ALL') {
      body = open.isEmpty
          ? [const DcnEmptyState(icon: 'clipboard', title: 'No open tasks', body: 'The department is all caught up.')]
          : [for (final t in open) TaskRow(task: t, onTap: () => context.push('/hod/review/${t.id}'))];
    } else {
      body = overdue.isEmpty
          ? [const DcnEmptyState(icon: 'checkCircle', title: 'None overdue', body: 'Great — nothing is overdue.')]
          : [for (final t in overdue) TaskRow(task: t, onTap: () => context.push('/hod/review/${t.id}'))];
    }

    return Column(
      children: [
        DcnHeaderBar(
          title: 'Tasks',
          sub: '${open.length} open · ${review.length} for review',
          right: [
            GestureDetector(
              onTap: () => context.push('/hod/assign'),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
                child: const DcnIcon('plus', size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
        Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: DcnSegmented(
            options: [
              (id: 'REVIEW', label: 'Review (${review.length})'),
              (id: 'ALL', label: 'All open'),
              (id: 'OVERDUE', label: 'Overdue'),
            ],
            value: _tab,
            onChanged: (v) => setState(() => _tab = v),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: body.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => body[i],
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.task, required this.onTap});
  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return DcnCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DcnAvatar(name: task.assigneeName, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(task.title,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                    ),
                    if (task.priority == TaskPriority.high)
                      const DcnChip(label: 'High', tone: DcnTone.danger, size: DcnButtonSize.sm),
                  ],
                ),
                const SizedBox(height: 3),
                Text('by ${task.assigneeName} · ${task.submittedAtLabel}',
                    style: TextStyle(fontSize: 12, color: c.textMuted)),
                if (task.submissionNote.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(left: BorderSide(color: c.brand, width: 3)),
                    ),
                    child: Text('"${task.submissionNote}"',
                        style: TextStyle(fontSize: 12.5, color: c.text, height: 1.4)),
                  ),
                ],
                if (task.attachments > 0) ...[
                  const SizedBox(height: 8),
                  DcnChip(
                    label: '${task.attachments} attachment${task.attachments > 1 ? 's' : ''}',
                    tone: DcnTone.brand,
                    size: DcnButtonSize.sm,
                    icon: 'image',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
