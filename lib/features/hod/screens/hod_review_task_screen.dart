import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_sheet.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/task.dart';
import '../data/hod_providers.dart';

class HodReviewTaskScreen extends ConsumerStatefulWidget {
  const HodReviewTaskScreen({super.key, required this.taskId});
  final String taskId;
  @override
  ConsumerState<HodReviewTaskScreen> createState() => _State();
}

class _State extends ConsumerState<HodReviewTaskScreen> {
  final _feedback = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _decide(bool approved) async {
    setState(() => _busy = true);
    try {
      await ref.read(hodRepositoryProvider).reviewTask(
            widget.taskId,
            approved: approved,
            feedback: _feedback.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approved ? 'Approved — worker notified' : 'Sent back to the worker'),
          behavior: SnackBarBehavior.floating,
        ));
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not save. Try again.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _openReject() async {
    final ok = await showDcnSheet<bool>(
      context: context,
      title: 'Send back for revisions',
      builder: (ctx) {
        final c = ctx.dcn;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('The worker gets an in-app notification with your feedback.',
                style: TextStyle(fontSize: 13, color: c.textMuted)),
            const SizedBox(height: 12),
            DcnField(
              label: 'Why are you rejecting?',
              controller: _feedback,
              placeholder: 'Be specific so they know what to fix…',
              multiline: true,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DcnButton(label: 'Cancel', variant: DcnButtonVariant.ghost, full: true, onPressed: () => Navigator.of(ctx).pop(false)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DcnButton(label: 'Send back', variant: DcnButtonVariant.danger, icon: 'send', full: true, onPressed: () => Navigator.of(ctx).pop(true)),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (ok == true) _decide(false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final task = ref.watch(hodTaskByIdProvider(widget.taskId));

    if (task == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(children: [
            DcnHeaderBar(title: 'Review', onBack: () => context.pop()),
            const Expanded(child: DcnEmptyState(icon: 'clipboard', title: 'Not found', body: 'This task is no longer in your queue.')),
          ]),
        ),
      );
    }

    final decided = task.status == TaskStatus.approved || task.status == TaskStatus.rejected;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Review submission', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DcnCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DcnChip(
                            label: decided ? task.status.label : 'Submitted · awaiting your review',
                            tone: task.status == TaskStatus.approved
                                ? DcnTone.success
                                : task.status == TaskStatus.rejected
                                    ? DcnTone.danger
                                    : DcnTone.warning,
                          ),
                          const SizedBox(height: 10),
                          Text(task.title,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.text, height: 1.2)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              DcnAvatar(name: task.assigneeName, size: 32),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task.assigneeName,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
                                  Text('Submitted ${task.submittedAtLabel}',
                                      style: TextStyle(fontSize: 11, color: c.textMuted)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (task.submissionNote.isNotEmpty) ...[
                      const DcnSectionHeader(title: "Worker's note"),
                      DcnCard(child: Text(task.submissionNote, style: TextStyle(fontSize: 14, color: c.text, height: 1.55))),
                    ],
                    if (task.attachments > 0) ...[
                      DcnSectionHeader(title: 'Attachments (${task.attachments})'),
                      for (var i = 0; i < task.attachments; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DcnCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(10)),
                                  child: DcnIcon('image', size: 18, color: c.brand),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('attachment-${i + 1}.jpg',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
                                      Text('tap to view', style: TextStyle(fontSize: 11, color: c.textMuted)),
                                    ],
                                  ),
                                ),
                                DcnIcon('arrowUpRight', size: 16, color: c.textDim),
                              ],
                            ),
                          ),
                        ),
                    ],
                    if (!decided) ...[
                      const DcnSectionHeader(title: 'Feedback (optional)'),
                      DcnField(
                        controller: _feedback,
                        placeholder: 'Notes back to the worker — visible to them',
                        multiline: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (!decided)
              Container(
                decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    DcnButton(label: 'Reject', variant: DcnButtonVariant.ghost, icon: 'x', onPressed: _busy ? null : _openReject),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DcnButton(label: 'Approve', variant: DcnButtonVariant.success, icon: 'check', full: true, loading: _busy, onPressed: _busy ? null : () => _decide(true)),
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
