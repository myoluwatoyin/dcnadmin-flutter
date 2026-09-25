import 'package:flutter/material.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/member.dart';

({DcnTone tone, String label}) memberStatus(Member m) {
  if (m.unreachable) return (tone: DcnTone.danger, label: 'Unreachable');
  if (m.isAtRisk) return (tone: DcnTone.warning, label: '${m.weeksAbsent}w absent');
  if (m.isFirstTimer) return (tone: DcnTone.info, label: 'First-Timer');
  return (tone: DcnTone.success, label: 'Active');
}

DcnTone priorityTone(String p) => switch (p) {
      'urgent' => DcnTone.danger,
      'high' => DcnTone.warning,
      'med' => DcnTone.info,
      _ => DcnTone.neutral,
    };

String priorityLabel(String p) => switch (p) {
      'urgent' => 'Urgent',
      'high' => 'High',
      'med' => 'Med',
      _ => 'Low',
    };

/// A member row in the directory.
class MemberRow extends StatelessWidget {
  const MemberRow({super.key, required this.member, this.onTap});
  final Member member;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final m = member;
    final s = memberStatus(m);
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
                Text(m.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                const SizedBox(height: 2),
                Text(
                  [m.school, m.level, if (m.lastAttended.isNotEmpty) 'Last: ${m.lastAttended}']
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DcnChip(label: s.label, tone: s.tone, size: DcnButtonSize.sm),
        ],
      ),
    );
  }
}
