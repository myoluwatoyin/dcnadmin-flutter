import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/team_worker.dart';
import '../data/hod_providers.dart';

class HodSubUnitsScreen extends ConsumerWidget {
  const HodSubUnitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final team = ref.watch(hodTeamProvider).valueOrNull ?? const <TeamWorker>[];

    // Group workers by sub-unit.
    final byUnit = <String, List<TeamWorker>>{};
    for (final w in team) {
      if (w.subUnit.isEmpty) continue;
      byUnit.putIfAbsent(w.subUnit, () => []).add(w);
    }
    final units = byUnit.keys.toList()..sort();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Sub-units', sub: '${units.length} units', onBack: () => context.pop()),
            Expanded(
              child: units.isEmpty
                  ? const DcnEmptyState(icon: 'grid', title: 'No sub-units', body: 'Your team has no sub-units yet.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: units.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final name = units[i];
                        final members = byUnit[name]!;
                        final subHod = members.where((w) => w.isSubHod).map((w) => w.name).firstOrNull;
                        return DcnCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(12)),
                                    child: DcnIcon('grid', size: 20, color: c.brand),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.text)),
                                        Text('${members.length} member${members.length == 1 ? '' : 's'}', style: TextStyle(fontSize: 12, color: c.textMuted)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  children: [
                                    DcnIcon('user', size: 14, color: c.textMuted),
                                    const SizedBox(width: 8),
                                    Text('Sub-HOD:', style: TextStyle(fontSize: 12, color: c.textMuted)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: subHod != null
                                          ? Text(subHod, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.text))
                                          : Text('Not assigned', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.warning)),
                                    ),
                                  ],
                                ),
                              ),
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
