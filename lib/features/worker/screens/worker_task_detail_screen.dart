import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_sheet.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/task.dart';
import '../data/worker_providers.dart';
import '../widgets/worker_rows.dart';

const _pipeline = <({TaskStatus status, String label})>[
  (status: TaskStatus.assigned, label: 'Assigned'),
  (status: TaskStatus.inProgress, label: 'Started'),
  (status: TaskStatus.submitted, label: 'Submitted'),
  (status: TaskStatus.approved, label: 'Approved'),
];

/// Task detail with status pipeline, brief, and a sticky action bar that
/// persists Start / Submit transitions to Firestore.
class WorkerTaskDetailScreen extends ConsumerStatefulWidget {
  const WorkerTaskDetailScreen({super.key, required this.taskId});
  final String taskId;

  @override
  ConsumerState<WorkerTaskDetailScreen> createState() => _State();
}

class _State extends ConsumerState<WorkerTaskDetailScreen> {
  bool _busy = false;

  Future<void> _setStatus(TaskStatus status, {String? note}) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(workerRepositoryProvider)
          .updateTaskStatus(widget.taskId, status, note: note);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == TaskStatus.inProgress
              ? 'Task started — keep going!'
              : 'Submitted for review.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not update the task. Try again.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSubmitSheet() async {
    final controller = TextEditingController();
    final submit = await showDcnSheet<bool>(
      context: context,
      title: 'Submit task',
      builder: (ctx) {
        final c = ctx.dcn;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your HOD will review this. Add a quick note on what you did.',
                style: TextStyle(fontSize: 13, color: c.textMuted)),
            const SizedBox(height: 12),
            DcnField(
              label: 'What did you complete?',
              controller: controller,
              placeholder: 'Quick note for your HOD…',
              multiline: true,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DcnButton(
                    label: 'Cancel',
                    variant: DcnButtonVariant.ghost,
                    full: true,
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DcnButton(
                    label: 'Submit for review',
                    icon: 'send',
                    full: true,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (submit == true) {
      await _setStatus(TaskStatus.submitted, note: controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final task = ref.watch(workerTaskByIdProvider(widget.taskId));

    if (task == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(
            children: [
              DcnHeaderBar(title: 'Task', onBack: () => context.pop()),
              const Expanded(
                child: DcnEmptyState(
                  icon: 'clipboard',
                  title: 'Task not found',
                  body: 'It may have been removed or reassigned.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pipelineIdx = _pipeline.indexWhere((p) => p.status == task.status);
    final effectiveIdx = task.status == TaskStatus.overdue ? 0 : pipelineIdx;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Task', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // header card
                    DcnCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DcnChip(
                                        label: task.status.label,
                                        tone: taskStatusTone(task.status)),
                                    const SizedBox(height: 10),
                                    Text(task.title,
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: c.text,
                                            height: 1.2,
                                            letterSpacing: -0.4)),
                                    if (task.assignedBy.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(task.assignedBy,
                                          style: TextStyle(
                                              fontSize: 12.5, color: c.textMuted)),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                width: 14,
                                height: 14,
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: taskPriorityColor(context, task.priority),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Divider(color: c.divider, height: 1),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _MetaCol(
                                  label: 'DUE',
                                  value: task.dueDate.isNotEmpty ? task.dueDate : '—',
                                  color: task.status == TaskStatus.overdue
                                      ? c.danger
                                      : c.text,
                                ),
                              ),
                              Expanded(
                                child: _MetaCol(
                                  label: 'PRIORITY',
                                  value: task.priority.name.toUpperCase(),
                                  color: c.text,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // pipeline
                    DcnCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PIPELINE',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: c.textMuted,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < _pipeline.length; i++) ...[
                                _PipelineNode(
                                  index: i,
                                  label: _pipeline[i].label,
                                  done: i <= effectiveIdx,
                                  current: i == effectiveIdx,
                                ),
                                if (i < _pipeline.length - 1)
                                  Expanded(
                                    child: Container(
                                      height: 2,
                                      margin: const EdgeInsets.only(top: 13),
                                      color: i < effectiveIdx ? c.brand : c.border,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const DcnSectionHeader(title: 'Brief'),
                      DcnCard(
                        child: Text(task.description,
                            style: TextStyle(fontSize: 13.5, color: c.text, height: 1.55)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // sticky action bar
            _ActionBar(
              task: task,
              busy: _busy,
              onStart: () => _setStatus(TaskStatus.inProgress),
              onSubmit: _openSubmitSheet,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaCol extends StatelessWidget {
  const _MetaCol({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.textMuted,
                letterSpacing: 0.5)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _PipelineNode extends StatelessWidget {
  const _PipelineNode({
    required this.index,
    required this.label,
    required this.done,
    required this.current,
  });
  final int index;
  final String label;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? c.brand : c.surface2,
            shape: BoxShape.circle,
            border: current
                ? Border.all(color: c.brandSoft, width: 4)
                : null,
          ),
          child: done
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('${index + 1}',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: c.textDim)),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: done ? c.text : c.textDim)),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.task,
    required this.busy,
    required this.onStart,
    required this.onSubmit,
  });
  final Task task;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    Widget? action;
    if (task.status == TaskStatus.assigned) {
      action = DcnButton(label: 'Start', icon: 'play', full: true, loading: busy, onPressed: busy ? null : onStart);
    } else if (task.status == TaskStatus.inProgress || task.status == TaskStatus.overdue) {
      action = DcnButton(label: 'Submit for review', icon: 'send', full: true, loading: busy, onPressed: busy ? null : onSubmit);
    } else if (task.status == TaskStatus.submitted || task.status == TaskStatus.underReview) {
      action = DcnButton(label: 'Pending review', icon: 'clock', variant: DcnButtonVariant.secondary, full: true, onPressed: null);
    } else if (task.status == TaskStatus.approved) {
      action = DcnButton(label: 'Approved', icon: 'checkCircle', variant: DcnButtonVariant.success, full: true, onPressed: null);
    } else if (task.status == TaskStatus.rejected) {
      action = DcnButton(label: 'Rework & resubmit', icon: 'refresh', full: true, loading: busy, onPressed: busy ? null : onSubmit);
    }
    if (action == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: action,
    );
  }
}
