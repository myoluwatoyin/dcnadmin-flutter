import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/scorecard.dart';
import '../../../models/team_worker.dart';
import '../data/hod_providers.dart';

class HodScorecardsScreen extends ConsumerStatefulWidget {
  const HodScorecardsScreen({super.key});
  @override
  ConsumerState<HodScorecardsScreen> createState() => _State();
}

class _State extends ConsumerState<HodScorecardsScreen> {
  String _tab = 'PENDING';

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final team = ref.watch(hodTeamProvider).valueOrNull ?? const <TeamWorker>[];
    final cards = ref.watch(hodScorecardsProvider).valueOrNull ?? const <Scorecard>[];

    // Map current-quarter status per worker uid.
    final statusByUid = <String, String>{};
    for (final s in cards) {
      if (s.quarter == 'Q2' && s.year == 2026 && s.uid.isNotEmpty) {
        statusByUid[s.uid] = s.statusWire.toUpperCase() == 'DRAFT' ? 'DRAFT' : 'DONE';
      }
    }

    final rows = team.map((w) {
      final st = statusByUid[w.uid] ?? 'PENDING';
      return (worker: w, status: st);
    }).toList();

    final done = rows.where((r) => r.status == 'DONE').length;
    final drafts = rows.where((r) => r.status == 'DRAFT').length;
    final pending = rows.where((r) => r.status == 'PENDING').length;
    final shown = rows.where((r) => r.status == _tab).toList();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(
              title: 'Q2 Scorecards',
              sub: '$done/${team.length} done · due in 14 days',
              onBack: () => context.pop(),
            ),
            Container(
              color: c.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: DcnSegmented(
                options: [
                  (id: 'PENDING', label: 'To do ($pending)'),
                  (id: 'DRAFT', label: 'Drafts ($drafts)'),
                  (id: 'DONE', label: 'Done ($done)'),
                ],
                value: _tab,
                onChanged: (v) => setState(() => _tab = v),
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? DcnEmptyState(
                      icon: 'award',
                      title: _tab == 'DONE' ? 'None done yet' : 'Nothing here',
                      body: _tab == 'PENDING' ? 'Everyone in this view is assessed.' : 'No workers in this view.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: shown.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final w = shown[i].worker;
                        final st = shown[i].status;
                        return DcnCard(
                          onTap: () => context.push('/hod/scorecard-entry/${w.uid}'),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              DcnAvatar(name: w.name, size: 40),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(w.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                                    Text('${w.subUnit} · Last: ${w.scorecardLast}/100', style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                                  ],
                                ),
                              ),
                              DcnChip(
                                label: st == 'DONE' ? 'Done' : st == 'DRAFT' ? 'Draft' : 'To do',
                                tone: st == 'DONE' ? DcnTone.success : st == 'DRAFT' ? DcnTone.warning : DcnTone.neutral,
                                size: DcnButtonSize.sm,
                              ),
                              const SizedBox(width: 6),
                              DcnIcon('chevronRight', size: 18, color: c.textDim),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
