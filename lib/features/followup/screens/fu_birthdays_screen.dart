import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/member.dart';
import '../data/fu_providers.dart';

class FuBirthdaysScreen extends ConsumerWidget {
  const FuBirthdaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final all = ref.watch(fuBirthdaysProvider);
    final today = all.where((m) => m.nextBirthdayLabel == 'Today').toList();
    final week = all.where((m) => m.nextBirthdayLabel != 'Today').toList();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Birthdays', sub: 'Next 7 days', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (today.isNotEmpty) ...[
                    const DcnSectionHeader(title: 'Today'),
                    for (final m in today) _TodayCard(m: m),
                  ],
                  const DcnSectionHeader(title: 'This week'),
                  if (week.isEmpty)
                    DcnCard(child: Text('No other birthdays this week.', style: TextStyle(fontSize: 13, color: c.textMuted)))
                  else
                    for (final m in week)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DcnCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              DcnAvatar(name: m.name, size: 40),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                                    Text(m.nextBirthdayLabel, style: TextStyle(fontSize: 12, color: c.textMuted)),
                                  ],
                                ),
                              ),
                              const DcnChip(label: 'Scheduled', tone: DcnTone.neutral, size: DcnButtonSize.sm),
                            ],
                          ),
                        ),
                      ),
                  const DcnSectionHeader(title: 'Birthday SMS template'),
                  DcnCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Members', style: TextStyle(fontSize: 12.5, color: c.textMuted, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            'Happy birthday, {first_name}! 🎂 The whole DCN family is celebrating you today. May this year be filled with God’s favour. — Pastor Femi',
                            style: TextStyle(fontSize: 13, color: c.text, height: 1.5, fontStyle: FontStyle.italic),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DcnButton(label: 'Edit template', variant: DcnButtonVariant.ghost, size: DcnButtonSize.sm, icon: 'edit', onPressed: () {}),
                      ],
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

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.m});
  final Member m;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DcnCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                DcnAvatar(name: m.name, size: 48),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.warning, shape: BoxShape.circle, border: Border.all(color: c.surface, width: 2)),
                    child: const Text('🎂', style: TextStyle(fontSize: 10)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.text)),
                  Text(m.phone, style: TextStyle(fontSize: 12, color: c.textMuted)),
                  const SizedBox(height: 6),
                  const DcnChip(label: 'Auto-SMS sent 7:00 AM', tone: DcnTone.success, size: DcnButtonSize.sm, icon: 'check'),
                ],
              ),
            ),
            DcnButton(label: 'Call', size: DcnButtonSize.sm, icon: 'phone', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
