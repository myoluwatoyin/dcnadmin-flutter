import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/member.dart';
import '../data/fu_providers.dart';

class FuSmsScreen extends ConsumerStatefulWidget {
  const FuSmsScreen({super.key});
  @override
  ConsumerState<FuSmsScreen> createState() => _State();
}

class _State extends ConsumerState<FuSmsScreen> {
  String _target = 'all';
  final _msg = TextEditingController();

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final members = ref.watch(fuMembersProvider).valueOrNull ?? const <Member>[];
    final counts = {
      'custom': 1,
      'all': members.length,
      'at_risk': members.where((m) => m.isAtRisk).length,
      'first': members.where((m) => m.isFirstTimer).length,
    };
    final count = counts[_target] ?? 0;
    final smsCount = _msg.text.isEmpty ? 0 : (_msg.text.length / 160).ceil();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Send SMS', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DcnSectionHeader(title: 'Who'),
                    for (final o in [
                      (id: 'custom', label: 'A specific member', icon: 'user'),
                      (id: 'all', label: 'All my members', icon: 'users'),
                      (id: 'at_risk', label: 'At-risk members', icon: 'alert'),
                      (id: 'first', label: 'First-timers', icon: 'star'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _target = o.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: _target == o.id ? c.brandSoft : c.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _target == o.id ? c.brand : c.border, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                DcnIcon(o.icon, size: 18, color: _target == o.id ? c.brand : c.textMuted),
                                const SizedBox(width: 12),
                                Expanded(child: Text(o.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _target == o.id ? c.brandInk : c.text))),
                                DcnChip(label: '${counts[o.id]}', tone: _target == o.id ? DcnTone.brand : DcnTone.neutral, size: DcnButtonSize.sm),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const DcnSectionHeader(title: 'Message'),
                    DcnCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          DcnField(controller: _msg, placeholder: 'Write your message…', multiline: true, onChanged: (_) => setState(() {})),
                          const SizedBox(height: 8),
                          Text('${_msg.text.length} / 160 chars · $smsCount SMS', style: TextStyle(fontSize: 11, color: c.textDim)),
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
                label: 'Send to $count ${count == 1 ? 'person' : 'people'}',
                icon: 'send',
                size: DcnButtonSize.lg,
                full: true,
                onPressed: _msg.text.trim().isEmpty
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message queued'), behavior: SnackBarBehavior.floating));
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
