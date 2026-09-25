import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/member.dart';
import '../data/fu_providers.dart';
import '../widgets/fu_widgets.dart';

const _filters = [
  (id: 'ALL', label: 'All'),
  (id: 'ACTIVE', label: 'Active'),
  (id: 'AT_RISK', label: 'At risk'),
  (id: 'FIRST', label: 'First-timers'),
  (id: 'UNREACH', label: 'Unreachable'),
];

class FuMembersScreen extends ConsumerStatefulWidget {
  const FuMembersScreen({super.key});
  @override
  ConsumerState<FuMembersScreen> createState() => _State();
}

class _State extends ConsumerState<FuMembersScreen> {
  String _filter = 'ALL';
  String _q = '';
  bool _scrolled = false;

  bool _match(Member m) {
    if (_filter == 'ACTIVE' && m.status != 'Active') return false;
    if (_filter == 'AT_RISK' && !m.isAtRisk) return false;
    if (_filter == 'FIRST' && !m.isFirstTimer) return false;
    if (_filter == 'UNREACH' && !m.unreachable) return false;
    if (_q.isNotEmpty && !m.name.toLowerCase().contains(_q.toLowerCase())) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final membersA = ref.watch(fuMembersProvider);
    final members = membersA.valueOrNull ?? const <Member>[];
    final atRisk = members.where((m) => m.isAtRisk).length;
    final filtered = members.where(_match).toList();

    return Column(
      children: [
        DcnHeaderBar(
          title: 'Members',
          sub: '${members.length} total · $atRisk at risk',
          right: [
            GestureDetector(
              onTap: () => context.push('/fu/sms'),
              child: Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle), child: DcnIcon('send', size: 18, color: c.text)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.push('/fu/add-member'),
              child: Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle), child: const DcnIcon('plus', size: 20, color: Colors.white)),
            ),
          ],
        ),
        Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              DcnField(icon: 'search', placeholder: 'Search by name…', onChanged: (v) => setState(() => _q = v)),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final f in _filters)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = f.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: _filter == f.id ? c.brand : c.surface2, borderRadius: BorderRadius.circular(999)),
                            child: Text(f.label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _filter == f.id ? Colors.white : c.textMuted)),
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
          child: membersA.isLoading && !membersA.hasValue
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const DcnEmptyState(icon: 'users', title: 'No members', body: 'No one matches this filter.')
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
                        itemBuilder: (_, i) => MemberRow(member: filtered[i], onTap: () => context.push('/fu/member/${filtered[i].id}')),
                      ),
                    ),
        ),
      ],
    );
  }
}
