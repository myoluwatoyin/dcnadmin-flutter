import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/scorecard.dart';
import '../data/pastor_providers.dart';

// ── Attendance analytics ─────────────────────────────────────
class PastorAttendanceScreen extends ConsumerStatefulWidget {
  const PastorAttendanceScreen({super.key});
  @override
  ConsumerState<PastorAttendanceScreen> createState() => _AttState();
}

class _AttState extends ConsumerState<PastorAttendanceScreen> {
  String _service = 'sunday';
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final a = ref.watch(analyticsProvider).valueOrNull ?? const {};
    final monthly = ((a['attendance_monthly'] as List?) ?? const []).cast<Map>();
    final services = ((a['services'] as List?) ?? const []).cast<Map>();
    final vals = monthly.map((m) => ((m[_service] ?? 0) as num).toInt()).toList();
    final maxV = vals.isEmpty ? 100 : (vals.reduce((x, y) => x > y ? x : y));

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Attendance analytics', sub: 'Last 6 months', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  DcnSegmented(
                    options: const [(id: 'sunday', label: 'Sunday'), (id: 'tuesday', label: 'Tuesday')],
                    value: _service,
                    onChanged: (v) => setState(() => _service = v),
                  ),
                  const SizedBox(height: 16),
                  DcnCard(
                    child: SizedBox(
                      height: 160,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < monthly.length; i++)
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('${vals[i]}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.textMuted)),
                                  const SizedBox(height: 4),
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 5),
                                    height: (vals[i] / maxV) * 110 + 8,
                                    decoration: BoxDecoration(color: c.brand.withValues(alpha: i == monthly.length - 1 ? 1 : 0.45), borderRadius: BorderRadius.circular(6)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('${(monthly[i]['month'] ?? '')}', style: TextStyle(fontSize: 10, color: c.textMuted, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const DcnSectionHeader(title: 'Recent services'),
                  for (final s in services)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DcnCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${s['name']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                                  Text('${s['date']}', style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                                ],
                              ),
                            ),
                            _pill(c, '${s['present']}', 'present', DcnTone.success),
                            const SizedBox(width: 6),
                            _pill(c, '${s['late']}', 'late', DcnTone.warning),
                            const SizedBox(width: 6),
                            _pill(c, '${s['absent']}', 'absent', DcnTone.danger),
                          ],
                        ),
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

  Widget _pill(DcnColors c, String v, String label, DcnTone tone) {
    final fg = switch (tone) { DcnTone.success => c.success, DcnTone.warning => c.warning, _ => c.danger };
    return Column(children: [
      Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
      Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c.textMuted)),
    ]);
  }
}

// ── Scorecard analytics ──────────────────────────────────────
class PastorScorecardAnalyticsScreen extends ConsumerWidget {
  const PastorScorecardAnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final scorecards = ref.watch(pastorScorecardsProvider).valueOrNull ?? const <Scorecard>[];
    final depts = ref.watch(deptHealthProvider);
    final q2 = scorecards.where((s) => s.quarter == 'Q2' && s.year == 2026).toList();
    final overallAvg = q2.isEmpty ? 0 : (q2.fold<int>(0, (s, x) => s + x.total) / q2.length).round();
    final passRate = q2.isEmpty ? 0 : ((q2.where((x) => x.pass).length / q2.length) * 100).round();
    final flagged = q2.where((x) => !x.pass).toList();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Scorecard analytics', sub: 'Q2 2026', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Row(children: [
                    Expanded(child: DcnStatTile(label: 'Assessed', value: '${q2.length}', icon: 'award', tone: DcnTone.brand)),
                    const SizedBox(width: 8),
                    Expanded(child: DcnStatTile(label: 'Avg score', value: '$overallAvg', icon: 'trending', tone: DcnTone.info)),
                    const SizedBox(width: 8),
                    Expanded(child: DcnStatTile(label: 'Pass rate', value: '$passRate%', icon: 'checkCircle', tone: passRate >= 70 ? DcnTone.success : DcnTone.warning)),
                  ]),
                  const DcnSectionHeader(title: 'By department'),
                  for (final d in depts)
                    Builder(builder: (_) {
                      final deptCards = q2.where((s) => scorecards.any((x) => x.uid == s.uid) && _deptMatch(ref, s.uid, d.code)).toList();
                      final done = d.scorecardsDone;
                      final avg = deptCards.isEmpty ? 0 : (deptCards.fold<int>(0, (a, x) => a + x.total) / deptCards.length).round();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DcnCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(width: 32, height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: d.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text(d.name[0], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: d.color))),
                                const SizedBox(width: 10),
                                Expanded(child: Text(d.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text))),
                                Text('$done assessed', style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                              ]),
                              const SizedBox(height: 10),
                              ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: (avg / 100).clamp(0, 1), minHeight: 6, backgroundColor: c.surface2, valueColor: AlwaysStoppedAnimation(avg >= 50 ? c.success : c.danger))),
                              const SizedBox(height: 4),
                              Text(avg > 0 ? 'Avg $avg/100' : 'No assessments yet', style: TextStyle(fontSize: 11, color: c.textMuted)),
                            ],
                          ),
                        ),
                      );
                    }),
                  if (flagged.isNotEmpty) ...[
                    const DcnSectionHeader(title: 'Flagged scorecards'),
                    for (final f in flagged)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DcnCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: c.dangerSoft, borderRadius: BorderRadius.circular(10)), child: Text('${f.total}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.danger))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(f.workerName.isNotEmpty ? f.workerName : 'Worker', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text)),
                              Text('Below pass mark', style: TextStyle(fontSize: 11.5, color: c.danger)),
                            ])),
                          ]),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _deptMatch(WidgetRef ref, String uid, String code) {
    final users = ref.read(allUsersProvider).valueOrNull ?? const [];
    for (final u in users) {
      if (u.uid == uid) return u.departmentName.toUpperCase().replaceAll('-', '').replaceAll(' ', '') == code || u.departmentName.toUpperCase() == code;
    }
    return false;
  }
}
