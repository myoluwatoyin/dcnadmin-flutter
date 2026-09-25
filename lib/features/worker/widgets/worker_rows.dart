import 'package:flutter/material.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/meeting.dart';
import '../../../models/task.dart';

DcnTone taskStatusTone(TaskStatus s) => switch (s) {
      TaskStatus.assigned => DcnTone.neutral,
      TaskStatus.inProgress => DcnTone.info,
      TaskStatus.submitted => DcnTone.warning,
      TaskStatus.underReview => DcnTone.brand,
      TaskStatus.approved => DcnTone.success,
      TaskStatus.rejected => DcnTone.danger,
      TaskStatus.overdue => DcnTone.danger,
    };

Color taskPriorityColor(BuildContext ctx, TaskPriority p) => switch (p) {
      TaskPriority.high => ctx.dcn.danger,
      TaskPriority.medium => ctx.dcn.warning,
      TaskPriority.low => ctx.dcn.success,
    };

/// Compact task card used in Home "Up next" and the Tasks list.
class TaskRow extends StatelessWidget {
  const TaskRow({super.key, required this.task, this.onTap});
  final Task task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return DcnCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: taskPriorityColor(context, task.priority),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: c.text,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DcnChip(
                        label: task.status.label,
                        tone: taskStatusTone(task.status),
                        size: DcnButtonSize.sm,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      DcnIcon('clock', size: 12, color: c.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Due ${task.dueDate}${task.assignedBy.isNotEmpty ? ' · ${task.assignedBy}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: c.textMuted),
                        ),
                      ),
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

DcnTone meetingTone(Meeting m) {
  if (m.status == MeetingStatus.cancelled) return DcnTone.danger;
  if (m.status == MeetingStatus.rescheduled) return DcnTone.warning;
  if (m.type == MeetingType.emergency) return DcnTone.danger;
  if (m.type == MeetingType.service) return DcnTone.info;
  return DcnTone.brand;
}

Color toneColor(BuildContext ctx, DcnTone t) => switch (t) {
      DcnTone.neutral => ctx.dcn.textMuted,
      DcnTone.brand => ctx.dcn.brand,
      DcnTone.success => ctx.dcn.success,
      DcnTone.warning => ctx.dcn.warning,
      DcnTone.danger => ctx.dcn.danger,
      DcnTone.info => ctx.dcn.info,
    };

/// Meeting row used on Home (compact) and the Schedule list.
class MeetingRow extends StatelessWidget {
  const MeetingRow({super.key, required this.meeting, this.compact = false, this.onTap});
  final Meeting meeting;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final m = meeting;
    final tone = meetingTone(m);
    return DcnCard(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                color: toneColor(context, tone),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        m.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.text,
                        ),
                      ),
                      if (m.status == MeetingStatus.rescheduled)
                        const DcnChip(label: 'Rescheduled', tone: DcnTone.warning, size: DcnButtonSize.sm),
                      if (m.status == MeetingStatus.cancelled)
                        const DcnChip(label: 'Cancelled', tone: DcnTone.danger, size: DcnButtonSize.sm),
                      if (m.type == MeetingType.emergency)
                        const DcnChip(label: 'Urgent', tone: DcnTone.danger, size: DcnButtonSize.sm, icon: 'alert'),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${m.date} · ${m.start}${m.end.isNotEmpty ? ' – ${m.end}' : ''}'
                    '${!compact && m.location.isNotEmpty ? ' · ${m.location}' : ''}',
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                ],
              ),
            ),
            if (!compact) DcnIcon('chevronRight', size: 18, color: c.textDim),
          ],
        ),
      ),
    );
  }
}

/// Small recent-activity row.
class ActivityItem extends StatelessWidget {
  const ActivityItem({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.sub,
  });

  final String icon;
  final DcnTone tone;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final ({Color bg, Color fg}) t = switch (tone) {
      DcnTone.neutral => (bg: c.surface2, fg: c.textMuted),
      DcnTone.brand => (bg: c.brandSoft, fg: c.brand),
      DcnTone.success => (bg: c.successSoft, fg: c.success),
      DcnTone.warning => (bg: c.warningSoft, fg: c.warning),
      DcnTone.danger => (bg: c.dangerSoft, fg: c.danger),
      DcnTone.info => (bg: c.infoSoft, fg: c.info),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(10)),
            child: DcnIcon(icon, size: 16, color: t.fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
                Text(sub, style: TextStyle(fontSize: 11.5, color: c.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The circular icon button used in screen headers (chat, bell).
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({super.key, required this.icon, this.onTap, this.dot = false});
  final String icon;
  final VoidCallback? onTap;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
            child: DcnIcon(icon, size: 18, color: c.text),
          ),
          if (dot)
            Positioned(
              top: 6,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: c.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface2, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
