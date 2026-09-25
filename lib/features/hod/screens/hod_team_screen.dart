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

class HodTeamScreen extends ConsumerStatefulWidget {
  const HodTeamScreen({super.key});
  @override
  ConsumerState<HodTeamScreen> createState() => _State();
}

class _State extends ConsumerState<HodTeamScreen> {
  String _filter = 'ALL';
  String _q = '';
  bool _scrolled = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final teamA = ref.watch(hodTeamProvider);
    final team = teamA.valueOrNull ?? const <TeamWorker>[];
    final apps = ref.watch(hodApplicationsProvider).valueOrNull ?? const [];

    final filtered = team.where((w) {
      if (_filter == 'SUBHOD' && !w.isSubHod) return false;
      if (_filter == 'AT_RISK' && !w.atRisk) return false;
      if (_filter == 'MISSING' && w.bothReports) return false;
      if (_q.isNotEmpty && !w.name.toLowerCase().contains(_q.toLowerCase())) return false;
      return true;
    }).toList();

    return Column(
      children: [
        DcnHeaderBar(
          title: 'Team',
          sub: '${team.length} workers',
          right: [
            GestureDetector(
              onTap: () => context.push('/hod/approvals'),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.brand, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  children: [
                    const DcnIcon('plus', size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text('${apps.length}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
        Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              DcnField(icon: 'search', placeholder: 'Find a worker…', onChanged: (v) => setState(() => _q = v)),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final f in [
                      (id: 'ALL', label: 'All (${team.length})'),
                      (id: 'SUBHOD', label: 'Sub-HODs'),
                      (id: 'AT_RISK', label: 'At risk'),
                      (id: 'MISSING', label: 'Missed reports'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = f.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _filter == f.id ? c.brand : c.surface2,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(f.label,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: _filter == f.id ? Colors.white : c.textMuted)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: teamA.isLoading && !teamA.hasValue
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const DcnEmptyState(icon: 'users', title: 'No workers', body: 'No one matches this filter.')
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        final s = n.metrics.pixels > 6;
                        if (s != _scrolled) setState(() => _scrolled = s);
                        return false;
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => TeamWorkerRow(
                          worker: filtered[i],
                          onTap: () => context.push('/hod/worker/${filtered[i].uid}'),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}
