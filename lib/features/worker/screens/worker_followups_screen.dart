import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_sheet.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/followup_assignment.dart';
import '../data/worker_providers.dart';

/// The six contact outcomes, matching the prototype's call-outcome sheet.
const _outcomes = <({String id, String label, String desc, Color color})>[
  (id: 'CALLED_SPOKE', label: 'Called & Spoke', desc: 'Reached and had a conversation', color: Color(0xFF10B981)),
  (id: 'VOICEMAIL', label: 'Left Voicemail', desc: 'Rang but went to voicemail', color: Color(0xFF3B82F6)),
  (id: 'NOT_PICKING', label: 'Not Picking', desc: 'Phone rang but no answer', color: Color(0xFFF59E0B)),
  (id: 'SWITCHED_OFF', label: 'Switched Off', desc: 'Phone unreachable', color: Color(0xFFEF4444)),
  (id: 'MESSAGED_SMS', label: 'Messaged via SMS', desc: 'Sent a text message', color: Color(0xFF8B5CF6)),
  (id: 'VISITED_PERSON', label: 'Visited in Person', desc: 'Met them face-to-face', color: Color(0xFF06B6D4)),
];

DcnTone _priorityTone(FollowupPriority p) => switch (p) {
      FollowupPriority.urgent => DcnTone.danger,
      FollowupPriority.high => DcnTone.warning,
      FollowupPriority.med => DcnTone.info,
      FollowupPriority.low => DcnTone.neutral,
    };

// ── List ─────────────────────────────────────────────────────
class WorkerFollowupsScreen extends ConsumerStatefulWidget {
  const WorkerFollowupsScreen({super.key});
  @override
  ConsumerState<WorkerFollowupsScreen> createState() => _ListState();
}

class _ListState extends ConsumerState<WorkerFollowupsScreen> {
  String _tab = 'PENDING';

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final all = ref.watch(workerFollowupsProvider).valueOrNull ?? const <FollowupAssignment>[];
    final pending = all.where((f) => f.status == FollowupStatus.pending).length;
    final done = all.where((f) => f.status == FollowupStatus.done).length;
    final items = all.where((f) {
      if (_tab == 'ALL') return true;
      if (_tab == 'PENDING') return f.status == FollowupStatus.pending;
      return f.status == FollowupStatus.done;
    }).toList();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(
              title: 'Follow-ups assigned to me',
              sub: '${all.length} total · cross-dept work',
              onBack: () => context.pop(),
            ),
            Container(
              color: c.surface,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.infoSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.info.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DcnIcon('alertCircle', size: 16, color: c.info),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'These are members the Follow-Up team asked you to check in on — usually a shared school, interest, or relationship. Separate from your dept tasks.',
                            style: TextStyle(fontSize: 12, color: c.text, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Segment(
                    options: [
                      (id: 'PENDING', label: 'To do ($pending)'),
                      (id: 'DONE', label: 'Done ($done)'),
                      (id: 'ALL', label: 'All'),
                    ],
                    value: _tab,
                    onChanged: (v) => setState(() => _tab = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const DcnEmptyState(
                      icon: 'checkCircle',
                      title: 'All done',
                      body: 'No follow-ups in this view right now.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _FollowupRow(
                        f: items[i],
                        onTap: () => context.push('/followup/${items[i].id}'),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowupRow extends StatelessWidget {
  const _FollowupRow({required this.f, required this.onTap});
  final FollowupAssignment f;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final done = f.status == FollowupStatus.done;
    return DcnCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          DcnAvatar(name: f.memberName, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(f.memberName,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                    ),
                    const SizedBox(width: 6),
                    DcnChip(label: f.priority.label, tone: _priorityTone(f.priority), size: DcnButtonSize.sm),
                  ],
                ),
                const SizedBox(height: 3),
                Text(f.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: c.textMuted, height: 1.4)),
                const SizedBox(height: 4),
                Text('${f.assignedAtLabel} · by ${f.assignedBy}',
                    style: TextStyle(fontSize: 11, color: c.textDim)),
                if (done && f.lastOutcome.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('✓ ${f.lastOutcome}',
                      style: TextStyle(
                          fontSize: 11.5, color: c.success, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          done
              ? DcnIcon('checkCircle', size: 20, color: c.success)
              : DcnIcon('chevronRight', size: 18, color: c.textDim),
        ],
      ),
    );
  }
}

// ── Detail ───────────────────────────────────────────────────
class WorkerFollowupDetailScreen extends ConsumerStatefulWidget {
  const WorkerFollowupDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<WorkerFollowupDetailScreen> createState() => _DetailState();
}

class _DetailState extends ConsumerState<WorkerFollowupDetailScreen> {
  bool _busy = false;

  Future<void> _log(String outcomeLabel, {String? note}) async {
    setState(() => _busy = true);
    try {
      await ref.read(workerRepositoryProvider).logFollowupOutcome(
            widget.id,
            outcome: outcomeLabel,
            note: note,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Logged: $outcomeLabel · sent to FU HOD'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not log. Try again.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openOutcomeSheet() async {
    final note = TextEditingController();
    await showDcnSheet<void>(
      context: context,
      title: 'What happened?',
      builder: (ctx) {
        final c = ctx.dcn;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final o in _outcomes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _log(o.label, note: note.text);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: o.color.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DcnIcon('checkCircle', size: 18, color: o.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.label,
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                              Text(o.desc,
                                  style: TextStyle(fontSize: 12, color: c.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            DcnField(label: 'Notes (optional)', controller: note, placeholder: 'What was discussed…', multiline: true),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final f = ref.watch(followupByIdProvider(widget.id));

    if (f == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(
            children: [
              DcnHeaderBar(title: 'Follow-up', onBack: () => context.pop()),
              const Expanded(
                child: DcnEmptyState(icon: 'users', title: 'Not found', body: 'This assignment is no longer available.'),
              ),
            ],
          ),
        ),
      );
    }

    final memberA = ref.watch(memberByIdProvider(f.memberId));
    final member = memberA.valueOrNull;
    final done = f.status == FollowupStatus.done;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Follow-up assignment', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          DcnAvatar(name: f.memberName, size: 72),
                          const SizedBox(height: 10),
                          Text(f.memberName,
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800, color: c.text)),
                          if (member != null && (member.school.isNotEmpty || member.level.isNotEmpty)) ...[
                            const SizedBox(height: 4),
                            Text('${member.school}${member.level.isNotEmpty ? ' · ${member.level}' : ''}',
                                style: TextStyle(fontSize: 13, color: c.textMuted)),
                          ],
                        ],
                      ),
                    ),
                    const DcnSectionHeader(title: 'Why you?'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.brandSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.brand.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.reason,
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: c.brandInk)),
                          const SizedBox(height: 8),
                          Text('Assigned by ${f.assignedBy} · ${f.assignedAtLabel}',
                              style: TextStyle(fontSize: 12, color: c.text)),
                        ],
                      ),
                    ),
                    const DcnSectionHeader(title: 'Reach out'),
                    Row(
                      children: [
                        _ContactBtn(icon: 'phone', label: 'Call', tone: DcnTone.brand, onTap: _openOutcomeSheet),
                        const SizedBox(width: 8),
                        _ContactBtn(icon: 'msg', label: 'SMS', tone: DcnTone.info, onTap: () => _log('Messaged via SMS')),
                        const SizedBox(width: 8),
                        _ContactBtn(icon: 'location', label: 'Visit', tone: DcnTone.success, onTap: () => _log('Visited in Person')),
                      ],
                    ),
                    if (member != null) ...[
                      const DcnSectionHeader(title: 'Quick info'),
                      DcnCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _InfoRow(icon: 'phone', label: 'Phone', value: member.phone, divider: true),
                            _InfoRow(icon: 'cake', label: 'Birthday', value: member.dob, divider: true),
                            _InfoRow(
                                icon: 'user',
                                label: 'Status',
                                value: '${member.status} · ${member.weeksAbsent}w absent'),
                          ],
                        ),
                      ),
                    ],
                    if (done) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.successSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            DcnIcon('checkCircle', size: 20, color: c.success),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Contact logged${f.lastOutcome.isNotEmpty ? ': ${f.lastOutcome}' : ''}',
                                      style: TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w700, color: c.success)),
                                  Text('The Follow-Up HOD has been notified.',
                                      style: TextStyle(fontSize: 11.5, color: c.text)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: DcnButton(
                label: done ? 'Log another outcome' : 'Log contact outcome',
                icon: 'phone',
                size: DcnButtonSize.lg,
                full: true,
                loading: _busy,
                onPressed: _busy ? null : _openOutcomeSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactBtn extends StatelessWidget {
  const _ContactBtn({required this.icon, required this.label, required this.tone, required this.onTap});
  final String icon;
  final String label;
  final DcnTone tone;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final ({Color bg, Color fg}) t = switch (tone) {
      DcnTone.info => (bg: c.infoSoft, fg: c.info),
      DcnTone.success => (bg: c.successSoft, fg: c.success),
      _ => (bg: c.brandSoft, fg: c.brand),
    };
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              DcnIcon(icon, size: 20, color: t.fg),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, this.divider = false});
  final String icon;
  final String label;
  final String value;
  final bool divider;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: c.divider)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(10)),
            child: DcnIcon(icon, size: 16, color: c.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value.isNotEmpty ? value : '—',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.options, required this.value, required this.onChanged});
  final List<({String id, String label})> options;
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(o.id),
                child: Container(
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == o.id ? c.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: value == o.id
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 2)]
                        : null,
                  ),
                  child: Text(o.label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: value == o.id ? c.text : c.textMuted)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
