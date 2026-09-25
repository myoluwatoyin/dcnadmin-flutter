import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/team_worker.dart';
import '../data/hod_providers.dart';
import '../widgets/hod_widgets.dart';

class HodAccountabilityScreen extends ConsumerWidget {
  const HodAccountabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final team = ref.watch(hodTeamProvider).valueOrNull ?? const <TeamWorker>[];
    final both = team.where((w) => w.bothReports).length;
    final partial = team.where((w) => w.someReports && !w.bothReports).length;
    final missed = team.where((w) => !w.someReports).length;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Accountability board', sub: 'Bible & prayer · this week', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Row(
                    children: [
                      Expanded(child: _Count(label: 'Both', value: both, tone: DcnTone.success)),
                      const SizedBox(width: 8),
                      Expanded(child: _Count(label: 'Partial', value: partial, tone: DcnTone.warning)),
                      const SizedBox(width: 8),
                      Expanded(child: _Count(label: 'Missed', value: missed, tone: DcnTone.danger)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (final w in team)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DcnCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            DcnAvatar(name: w.name, size: 36),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(w.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text)),
                                  Text(w.subUnit, style: TextStyle(fontSize: 11, color: c.textMuted)),
                                ],
                              ),
                            ),
                            StatusPill(icon: w.bibleReport ? 'check' : 'x', label: 'Bible', ok: w.bibleReport),
                            const SizedBox(width: 6),
                            StatusPill(icon: w.prayerReport ? 'check' : 'x', label: 'Prayer', ok: w.prayerReport),
                            if (!w.bothReports)
                              GestureDetector(
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Reminder sent to ${w.name.split(' ').first}'), behavior: SnackBarBehavior.floating),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: DcnIcon('bell', size: 16, color: c.brand),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  DcnButton(
                    label: "Nudge everyone who hasn't submitted",
                    variant: DcnButtonVariant.ghost,
                    icon: 'send',
                    full: true,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Reminder sent to ${partial + missed} workers'), behavior: SnackBarBehavior.floating),
                    ),
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

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value, required this.tone});
  final String label;
  final int value;
  final DcnTone tone;
  @override
  Widget build(BuildContext context) {
    final t = toneColors(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: t.fg)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.fg)),
        ],
      ),
    );
  }
}
