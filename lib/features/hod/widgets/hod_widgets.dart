import 'package:flutter/material.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/team_worker.dart';

({Color bg, Color fg}) toneColors(BuildContext ctx, DcnTone tone) {
  final c = ctx.dcn;
  return switch (tone) {
    DcnTone.neutral => (bg: c.surface2, fg: c.textMuted),
    DcnTone.brand => (bg: c.brandSoft, fg: c.brand),
    DcnTone.success => (bg: c.successSoft, fg: c.success),
    DcnTone.warning => (bg: c.warningSoft, fg: c.warning),
    DcnTone.danger => (bg: c.dangerSoft, fg: c.danger),
    DcnTone.info => (bg: c.infoSoft, fg: c.info),
  };
}

/// A 2-line quick-action tile used on dashboards.
class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.sub,
    this.tone = DcnTone.brand,
    this.onTap,
  });

  final String icon;
  final String label;
  final String sub;
  final DcnTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final t = toneColors(context, tone);
    return DcnCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(10)),
            child: DcnIcon(icon, size: 18, color: t.fg),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 11.5, color: c.textMuted)),
        ],
      ),
    );
  }
}

/// A small tonal status pill (Bible/Prayer/tasks/scorecard indicators).
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.icon,
    required this.label,
    this.ok = false,
    this.warn = false,
    this.sub,
  });

  final String icon;
  final String label;
  final bool ok;
  final bool warn;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final tone = ok
        ? DcnTone.success
        : warn
            ? DcnTone.danger
            : DcnTone.warning;
    final t = toneColors(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DcnIcon(icon, size: 11, color: t.fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.fg)),
          if (sub != null)
            Text(' · $sub',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.fg)),
        ],
      ),
    );
  }
}

/// A worker card in the HOD team list, with a status-pill row.
class TeamWorkerRow extends StatelessWidget {
  const TeamWorkerRow({super.key, required this.worker, this.onTap});
  final TeamWorker worker;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final w = worker;
    return DcnCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DcnAvatar(name: w.name, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(w.name,
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                        ),
                        if (w.isSubHod) ...[
                          const SizedBox(width: 6),
                          const DcnChip(label: 'Sub-HOD', tone: DcnTone.brand, size: DcnButtonSize.sm),
                        ],
                        if (w.atRisk) ...[
                          const SizedBox(width: 6),
                          const DcnChip(label: 'At risk', tone: DcnTone.danger, size: DcnButtonSize.sm, icon: 'alert'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${w.subUnit} · ${w.attendanceRate}% attendance',
                        style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusPill(icon: w.bibleReport ? 'check' : 'x', label: 'Bible', ok: w.bibleReport),
              StatusPill(icon: w.prayerReport ? 'check' : 'x', label: 'Prayer', ok: w.prayerReport),
              StatusPill(
                icon: 'clipboard',
                label: '${w.tasksOpen} tasks',
                ok: w.tasksOverdue == 0,
                warn: w.tasksOverdue > 0,
                sub: w.tasksOverdue > 0 ? '${w.tasksOverdue} overdue' : null,
              ),
              StatusPill(
                icon: 'award',
                label: 'Q1: ${w.scorecardLast}',
                ok: w.scorecardLast >= 70,
                warn: w.scorecardLast < 50,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
