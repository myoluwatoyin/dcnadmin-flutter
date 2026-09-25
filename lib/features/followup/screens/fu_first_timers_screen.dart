import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/member.dart';
import '../data/fu_providers.dart';

const _stages = <({String id, String label, DcnTone tone})>[
  (id: 'Contacted', label: 'Contacted', tone: DcnTone.info),
  (id: 'Not Reachable', label: 'Not reachable', tone: DcnTone.danger),
  (id: 'Attending', label: 'Attending', tone: DcnTone.warning),
  (id: 'Returning', label: 'Returning', tone: DcnTone.success),
];

class FuFirstTimersScreen extends ConsumerWidget {
  const FuFirstTimersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final firstTimers = ref.watch(fuFirstTimersProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'First-timer pipeline', sub: '${firstTimers.length} in flight', onBack: () => context.pop()),
            Expanded(
              child: firstTimers.isEmpty
                  ? const DcnEmptyState(icon: 'star', title: 'No first-timers', body: 'New first-timers you welcome will appear here.')
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        for (final s in _stages)
                          _Stage(
                            label: s.label,
                            tone: s.tone,
                            members: firstTimers.where((m) => m.pipelineStatus == s.id).toList(),
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

class _Stage extends StatelessWidget {
  const _Stage({required this.label, required this.tone, required this.members});
  final String label;
  final DcnTone tone;
  final List<Member> members;

  Color _toneColor(BuildContext ctx) => switch (tone) {
        DcnTone.info => ctx.dcn.info,
        DcnTone.danger => ctx.dcn.danger,
        DcnTone.warning => ctx.dcn.warning,
        _ => ctx.dcn.success,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DcnSectionHeader(title: '$label · ${members.length}'),
        if (members.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DcnCard(child: Center(child: Text('No one in this stage', style: TextStyle(fontSize: 12.5, color: c.textDim)))),
          )
        else
          for (final m in members)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DcnCard(
                onTap: () => context.push('/fu/member/${m.id}'),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        DcnAvatar(name: m.name, size: 40),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: _toneColor(context), borderRadius: BorderRadius.circular(999), border: Border.all(color: c.surface, width: 2)),
                            child: Text('W${m.weekNumber}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                          Text('${m.school} · ${m.level} · Joined ${m.firstSeen}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.textMuted)),
                        ],
                      ),
                    ),
                    DcnIcon('chevronRight', size: 18, color: c.textDim),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 8),
      ],
    );
  }
}
