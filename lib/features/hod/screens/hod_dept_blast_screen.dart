import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/team_worker.dart';
import '../data/hod_providers.dart';

class HodDeptBlastScreen extends ConsumerStatefulWidget {
  const HodDeptBlastScreen({super.key});
  @override
  ConsumerState<HodDeptBlastScreen> createState() => _State();
}

class _State extends ConsumerState<HodDeptBlastScreen> {
  final _msg = TextEditingController();
  String _audience = 'ALL';
  bool _sms = true;

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final team = ref.watch(hodTeamProvider).valueOrNull ?? const <TeamWorker>[];
    final all = team.length;
    final subhods = team.where((w) => w.isSubHod).length;
    final behind = team.where((w) => !w.bothReports).length;
    final count = _audience == 'ALL' ? all : _audience == 'SUBHOD' ? subhods : behind;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Dept message', sub: 'Send to your team', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DcnSectionHeader(title: 'Who'),
                    for (final o in [
                      (id: 'ALL', label: 'Whole department', icon: 'users', count: all),
                      (id: 'SUBHOD', label: 'Sub-HODs only', icon: 'star', count: subhods),
                      (id: 'MISSING', label: 'Workers behind on reports', icon: 'alert', count: behind),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _audience = o.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: _audience == o.id ? c.brandSoft : c.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _audience == o.id ? c.brand : c.border, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                DcnIcon(o.icon, size: 16, color: _audience == o.id ? c.brand : c.textMuted),
                                const SizedBox(width: 10),
                                Expanded(child: Text(o.label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _audience == o.id ? c.brandInk : c.text))),
                                DcnChip(label: '${o.count}', tone: _audience == o.id ? DcnTone.brand : DcnTone.neutral, size: DcnButtonSize.sm),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const DcnSectionHeader(title: 'Message'),
                    DcnField(controller: _msg, placeholder: "What's the message?", multiline: true, onChanged: (_) => setState(() {})),
                    const DcnSectionHeader(title: 'Channels'),
                    DcnCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              DcnIcon('bell', size: 18, color: c.brand),
                              const SizedBox(width: 12),
                              Expanded(child: Text('In-app push', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text))),
                              Text('Always', style: TextStyle(fontSize: 12, color: c.textMuted, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Divider(color: c.divider, height: 24),
                          Row(
                            children: [
                              DcnIcon('msg', size: 18, color: c.brand),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Also send as SMS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text))),
                              DcnToggle(value: _sms, onChanged: (v) => setState(() => _sms = v)),
                            ],
                          ),
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
              child: DcnButton(
                label: 'Send to $count',
                icon: 'send',
                size: DcnButtonSize.lg,
                full: true,
                onPressed: _msg.text.trim().isEmpty
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Sent to $count ${count == 1 ? 'person' : 'people'}'),
                          behavior: SnackBarBehavior.floating,
                        ));
                        context.pop();
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
