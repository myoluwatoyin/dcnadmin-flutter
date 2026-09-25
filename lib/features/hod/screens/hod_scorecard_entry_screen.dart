import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../data/hod_providers.dart';

const _cats = <({String key, String label, int max, bool critical})>[
  (key: 'teach', label: 'Teachability', max: 40, critical: true),
  (key: 'enthusiasm', label: 'Enthusiasm', max: 15, critical: true),
  (key: 'interest', label: 'Interest', max: 20, critical: false),
  (key: 'exam', label: 'Exam / Test', max: 15, critical: false),
  (key: 'attendance', label: 'Attendance', max: 10, critical: true),
];

class HodScorecardEntryScreen extends ConsumerStatefulWidget {
  const HodScorecardEntryScreen({super.key, required this.uid});
  final String uid;
  @override
  ConsumerState<HodScorecardEntryScreen> createState() => _State();
}

class _State extends ConsumerState<HodScorecardEntryScreen> {
  final Map<String, int> _scores = {
    'teach': 28, 'enthusiasm': 11, 'interest': 15, 'exam': 11, 'attendance': 8,
  };
  final _notes = TextEditingController();
  bool _busy = false;

  int get _total => _scores.values.fold(0, (a, b) => a + b);

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save({required bool draft}) async {
    final w = ref.read(hodWorkerByIdProvider(widget.uid));
    final dept = ref.read(hodDeptProvider);
    final hod = ref.read(authStateProvider).valueOrNull?.fullName ?? 'HOD';
    if (w == null || dept == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(hodRepositoryProvider).submitScorecard(
            workerUid: w.uid,
            workerName: w.name,
            subUnit: w.subUnit,
            dept: dept,
            quarter: 'Q2',
            year: 2026,
            categories: [
              for (final c in _cats)
                (label: c.label, score: _scores[c.key]!, max: c.max, critical: c.critical),
            ],
            total: _total,
            hodName: hod,
            hodNote: _notes.text,
            draft: draft,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(draft ? 'Saved as draft' : 'Assessment saved · ${w.name.split(' ').first} notified'),
          behavior: SnackBarBehavior.floating,
        ));
        if (!draft) context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save. Try again.'), behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final w = ref.watch(hodWorkerByIdProvider(widget.uid));
    if (w == null) {
      return Scaffold(backgroundColor: c.bg, body: SafeArea(child: Column(children: [DcnHeaderBar(title: 'Assessment', onBack: () => context.pop()), const Expanded(child: DcnEmptyState(icon: 'award', title: 'Worker not found', body: ''))])));
    }
    final passed = _total >= 50;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(
              title: 'Q2 Assessment',
              sub: w.name,
              onBack: () => context.pop(),
              right: [
                GestureDetector(
                  onTap: _busy ? null : () => _save(draft: true),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(999)),
                    child: Text('Save draft', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.text)),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: passed ? [const Color(0xFF34D399), const Color(0xFF059669)] : [const Color(0xFFF87171), const Color(0xFFDC2626)],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('RUNNING TOTAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.85), letterSpacing: 0.5)),
                                Text('$_total/100', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                                Text(passed ? 'Pass mark cleared (50)' : '${50 - _total} from pass mark',
                                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
                              ],
                            ),
                          ),
                          DcnAvatar(name: w.name, size: 56),
                        ],
                      ),
                    ),
                    const DcnSectionHeader(title: 'Score breakdown'),
                    for (final cat in _cats)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DcnCard(
                          child: Column(
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
                                    TextSpan(text: '${_scores[cat.key]}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.text)),
                                    TextSpan(text: ' / ${cat.max}', style: TextStyle(fontSize: 11, color: c.textDim, fontWeight: FontWeight.w600)),
                                  ])),
                                ],
                              ),
                              SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: c.brand,
                                  inactiveTrackColor: c.surface2,
                                  thumbColor: c.brand,
                                  overlayColor: c.brand.withValues(alpha: 0.15),
                                  trackHeight: 4,
                                ),
                                child: Slider(
                                  value: _scores[cat.key]!.toDouble(),
                                  min: 0,
                                  max: cat.max.toDouble(),
                                  divisions: cat.max,
                                  onChanged: (v) => setState(() => _scores[cat.key] = v.round()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const DcnSectionHeader(title: 'HOD notes'),
                    DcnField(controller: _notes, placeholder: "Strengths, areas to grow, pastoral concerns…", multiline: true),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: c.infoSoft, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PASS RULE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c.info, letterSpacing: 0.4)),
                          const SizedBox(height: 4),
                          Text('Total ≥ 50/100. The critical indicators (Teachability, Enthusiasm, Attendance) must show — a worker cannot pass on Interest + Exam alone.',
                              style: TextStyle(fontSize: 12, color: c.text, height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  DcnButton(label: 'Draft', variant: DcnButtonVariant.ghost, onPressed: _busy ? null : () => _save(draft: true)),
                  const SizedBox(width: 10),
                  Expanded(child: DcnButton(label: 'Submit assessment', icon: 'check', size: DcnButtonSize.lg, full: true, loading: _busy, onPressed: _busy ? null : () => _save(draft: false))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
