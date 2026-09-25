import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/accountability.dart';
import '../data/worker_providers.dart';

class WorkerAccountabilityScreen extends ConsumerWidget {
  const WorkerAccountabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final async = ref.watch(workerAccountabilityProvider);
    final a = async.valueOrNull;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(
              title: 'Accountability',
              sub: 'Your peer check-in',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: async.isLoading && !async.hasValue
                  ? const Center(child: CircularProgressIndicator())
                  : a == null
                      ? const DcnEmptyState(
                          icon: 'users',
                          title: 'No partner yet',
                          body: 'Your HOD will pair you with an accountability partner.')
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            // partner card
                            DcnCard(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      DcnAvatar(name: a.partnerName, size: 56),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('YOUR PARTNER',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: c.textMuted,
                                                    letterSpacing: 0.5)),
                                            const SizedBox(height: 2),
                                            Text(a.partnerName,
                                                style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w800,
                                                    color: c.text)),
                                            Text(a.partnerDept,
                                                style: TextStyle(fontSize: 12.5, color: c.textMuted)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DcnButton(
                                            label: 'Call',
                                            icon: 'phone',
                                            variant: DcnButtonVariant.secondary,
                                            full: true,
                                            onPressed: () {}),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: DcnButton(
                                            label: 'Message', icon: 'msg', full: true, onPressed: () {}),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const DcnSectionHeader(title: "This week's check-in"),
                            DcnCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Did you both submit Bible/prayer reports?',
                                      style: TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _CheckTile(
                                          name: 'You',
                                          submitted: a.youSubmitted,
                                          label: a.youSubmittedLabel,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _CheckTile(
                                          name: a.partnerName.split(' ').first,
                                          submitted: a.partnerSubmitted,
                                          label: a.partnerSubmittedLabel,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!a.partnerSubmitted) ...[
                                    const SizedBox(height: 14),
                                    DcnButton(
                                      label: 'Nudge ${a.partnerName.split(' ').first} to submit',
                                      variant: DcnButtonVariant.secondary,
                                      icon: 'msg',
                                      full: true,
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                          content: Text('Reminder sent'),
                                          behavior: SnackBarBehavior.floating,
                                        ));
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const DcnSectionHeader(title: 'Past weeks'),
                            for (final ci in a.history)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _HistoryRow(ci: ci),
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

class _CheckTile extends StatelessWidget {
  const _CheckTile({required this.name, required this.submitted, required this.label});
  final String name;
  final bool submitted;
  final String label;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final tone = submitted ? c.success : c.warning;
    final bg = submitted ? c.successSoft : c.warningSoft;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          DcnIcon(submitted ? 'check' : 'clock', size: 20, color: tone),
          const SizedBox(height: 6),
          Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.text)),
          Text(label, style: TextStyle(fontSize: 11, color: tone)),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.ci});
  final CheckIn ci;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return DcnCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          DcnIcon(ci.both ? 'checkCircle' : 'alertCircle',
              size: 18, color: ci.both ? c.success : c.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(ci.week,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
          ),
          DcnChip(
            label: ci.both ? 'Both submitted' : 'One missed',
            tone: ci.both ? DcnTone.success : DcnTone.warning,
            size: DcnButtonSize.sm,
          ),
        ],
      ),
    );
  }
}
