import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_sheet.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/scorecard.dart';
import '../data/worker_providers.dart';

class WorkerScorecardsScreen extends ConsumerStatefulWidget {
  const WorkerScorecardsScreen({super.key});
  @override
  ConsumerState<WorkerScorecardsScreen> createState() => _State();
}

class _State extends ConsumerState<WorkerScorecardsScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final async = ref.watch(workerScorecardsProvider);
    final all = async.valueOrNull ?? const <Scorecard>[];
    final detailed = all.where((s) => s.hasDetail).toList();

    final selected = detailed.isEmpty
        ? null
        : detailed.firstWhere((s) => s.id == _selectedId, orElse: () => detailed.first);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(
              title: 'Scorecards',
              sub: 'Your quarterly assessments',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: async.isLoading && !async.hasValue
                  ? const Center(child: CircularProgressIndicator())
                  : all.isEmpty
                      ? const DcnEmptyState(
                          icon: 'award',
                          title: 'No scorecards yet',
                          body: 'Your HOD publishes quarterly assessments here.')
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            if (detailed.length > 1) ...[
                              DcnSegmented(
                                options: [
                                  for (final s in detailed) (id: s.id, label: s.quarter),
                                ],
                                value: selected!.id,
                                onChanged: (id) => setState(() => _selectedId = id),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (selected != null) ...[
                              _Hero(s: selected),
                              const DcnSectionHeader(title: 'Breakdown'),
                              _Breakdown(s: selected),
                              if (selected.hodNote.isNotEmpty) ...[
                                const DcnSectionHeader(title: 'HOD notes'),
                                _HodNote(
                                  s: selected,
                                  onAcknowledge: () => _acknowledge(selected),
                                  onDispute: () => _openDispute(selected),
                                ),
                              ],
                            ],
                            const DcnSectionHeader(title: 'History'),
                            for (final h in all)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _HistoryRow(s: h),
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acknowledge(Scorecard s) async {
    await ref.read(workerRepositoryProvider).setScorecardAck(s.id, AckStatus.acknowledged);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Scorecard acknowledged'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _openDispute(Scorecard s) async {
    final text = TextEditingController();
    await showDcnSheet<void>(
      context: context,
      title: 'Dispute scorecard',
      builder: (ctx) {
        final c = ctx.dcn;
        var busy = false;
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Future<void> send() async {
              if (text.text.trim().isEmpty) return;
              setSheet(() => busy = true);
              try {
                await ref.read(workerRepositoryProvider).setScorecardAck(
                      s.id,
                      AckStatus.disputed,
                      disputeText: text.text,
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Dispute sent to your HOD'),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } catch (_) {
                setSheet(() => busy = false);
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Politely explain what you think was assessed unfairly. Your HOD reviews disputes before the quarter closes.',
                  style: TextStyle(fontSize: 12.5, color: c.textMuted, height: 1.5),
                ),
                const SizedBox(height: 12),
                DcnField(
                  label: 'Your note to the HOD',
                  controller: text,
                  placeholder: "e.g. My attendance score doesn't reflect the two services I ushered for Media…",
                  multiline: true,
                ),
                const SizedBox(height: 14),
                DcnButton(
                  label: busy ? 'Sending…' : 'Submit dispute',
                  icon: 'send',
                  full: true,
                  loading: busy,
                  onPressed: busy ? null : send,
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.s});
  final Scorecard s;
  @override
  Widget build(BuildContext context) {
    final colors = s.pass
        ? [const Color(0xFF34D399), const Color(0xFF059669)]
        : [const Color(0xFFF87171), const Color(0xFFDC2626)];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${s.label} · ${s.pass ? 'Pass' : 'Below pass mark'}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${s.total}',
                  style: const TextStyle(
                      fontSize: 56, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
              const SizedBox(width: 6),
              Text('/ 100',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.7))),
            ],
          ),
          if (s.hodName.isNotEmpty || s.assessedAt.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Assessed by ${s.hodName}${s.assessedAt.isNotEmpty ? ' · ${s.assessedAt}' : ''}',
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.s});
  final Scorecard s;
  @override
  Widget build(BuildContext context) {
    return DcnCard(
      child: Column(
        children: [
          for (var i = 0; i < s.categories.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _CategoryBar(cat: s.categories[i]),
          ],
        ],
      ),
    );
  }

  static Color barColor(BuildContext ctx, double pct) {
    final c = ctx.dcn;
    if (pct >= 70) return c.success;
    if (pct >= 50) return c.brand;
    return c.danger;
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.cat});
  final ScorecardCategory cat;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(cat.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
            if (cat.critical) ...[
              const SizedBox(width: 6),
              const DcnChip(label: 'Critical', tone: DcnTone.warning, size: DcnButtonSize.sm),
            ],
            const Spacer(),
            Text.rich(TextSpan(children: [
              TextSpan(
                  text: '${cat.score}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
              TextSpan(text: '/${cat.max}', style: TextStyle(fontSize: 13, color: c.textDim)),
            ])),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: cat.pct / 100,
            minHeight: 8,
            backgroundColor: c.surface2,
            valueColor: AlwaysStoppedAnimation(_Breakdown.barColor(context, cat.pct)),
          ),
        ),
      ],
    );
  }
}

class _HodNote extends StatelessWidget {
  const _HodNote({required this.s, required this.onAcknowledge, required this.onDispute});
  final Scorecard s;
  final VoidCallback onAcknowledge;
  final VoidCallback onDispute;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return DcnCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DcnAvatar(name: s.hodName, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${s.hodName} · ${s.quarter} HOD',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.text)),
                    const SizedBox(height: 6),
                    Text(s.hodNote, style: TextStyle(fontSize: 13, color: c.text, height: 1.55)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: c.divider, height: 1),
          const SizedBox(height: 14),
          if (s.ackStatus == AckStatus.acknowledged)
            Row(children: [
              DcnIcon('checkCircle', size: 18, color: c.success),
              const SizedBox(width: 8),
              Text('You acknowledged this scorecard.',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.success)),
            ])
          else if (s.ackStatus == AckStatus.disputed)
            Row(children: [
              DcnIcon('alertCircle', size: 18, color: c.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text("Dispute sent to your HOD — they'll respond soon.",
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.warning)),
              ),
            ])
          else
            Row(
              children: [
                Expanded(
                  child: DcnButton(
                    label: 'Dispute',
                    variant: DcnButtonVariant.ghost,
                    size: DcnButtonSize.sm,
                    icon: 'alertCircle',
                    full: true,
                    onPressed: onDispute,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DcnButton(
                    label: 'Acknowledge',
                    variant: DcnButtonVariant.success,
                    size: DcnButtonSize.sm,
                    icon: 'check',
                    full: true,
                    onPressed: onAcknowledge,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.s});
  final Scorecard s;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return DcnCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: s.pass ? c.successSoft : c.dangerSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${s.total}',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: s.pass ? c.success : c.danger)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.label,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text)),
                Text(s.pass ? 'Passed' : 'Below pass mark',
                    style: TextStyle(fontSize: 12, color: c.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
