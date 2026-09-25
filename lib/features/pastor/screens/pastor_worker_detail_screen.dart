import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_sheet.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/team_worker.dart';
import '../data/pastor_providers.dart';

class PastorWorkerDetailScreen extends ConsumerWidget {
  const PastorWorkerDetailScreen({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final w = ref.watch(pastorWorkerByIdProvider(uid)).valueOrNull;
    if (w == null) {
      return Scaffold(backgroundColor: c.bg, body: SafeArea(child: Column(children: [DcnHeaderBar(title: 'Worker', onBack: () => context.pop()), const Expanded(child: DcnEmptyState(icon: 'user', title: 'Not found', body: ''))])));
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: w.name, sub: [w.departmentName, w.subUnit].where((s) => s.isNotEmpty).join(' · '), onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (w.isSuspended)
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: c.dangerSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.danger.withValues(alpha: 0.4))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DcnIcon('lock', size: 18, color: c.danger),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Suspended — cannot log in', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.danger)),
                                if (w.suspendReason.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text('Reason: ${w.suspendReason}', style: TextStyle(fontSize: 11.5, color: c.text)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  DcnCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            DcnAvatar(name: w.name, size: 56),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Flexible(child: Text(w.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.text))),
                                    const SizedBox(width: 6),
                                    DcnChip(label: w.isHod ? 'HOD' : w.isSubHod ? 'Sub-HOD' : 'Worker', tone: w.isHod ? DcnTone.brand : w.isSubHod ? DcnTone.info : DcnTone.neutral, size: DcnButtonSize.sm),
                                  ]),
                                  const SizedBox(height: 3),
                                  Text('${w.departmentName} · ${w.weeksWithUs} wks with us', style: TextStyle(fontSize: 12, color: c.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: _mini(c, 'Attendance', '${w.attendanceRate}%')),
                          Expanded(child: _mini(c, 'Scorecard', '${w.scorecardLast}')),
                          Expanded(child: _mini(c, 'Open tasks', '${w.tasksOpen}')),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DcnCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(children: [
                      _row(c, 'user', 'Member ID', w.memberId.isNotEmpty ? w.memberId : '—', divider: true),
                      _row(c, 'phone', 'Phone', w.phone.isNotEmpty ? w.phone : '—', divider: true),
                      _row(c, 'msg', 'Email', w.email.isNotEmpty ? w.email : '—', divider: true),
                      _row(c, 'users', 'Role', '${w.isHod ? 'HOD' : w.isSubHod ? 'Sub-HOD' : 'Worker'} · ${w.departmentName}', divider: false),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  DcnButton(label: 'Send SMS to ${w.name.split(' ').first}', variant: DcnButtonVariant.secondary, icon: 'send', full: true, onPressed: () => _sms(context, w)),
                  const SizedBox(height: 8),
                  if (w.isSuspended)
                    DcnButton(label: 'Reinstate worker', variant: DcnButtonVariant.success, icon: 'check', full: true, onPressed: () => _reinstate(context, ref, w))
                  else
                    DcnButton(label: 'Suspend worker', variant: DcnButtonVariant.danger, icon: 'lock', full: true, onPressed: () => _suspend(context, ref, w)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(DcnColors c, String label, String value) => Column(children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w600)),
      ]);

  Widget _row(DcnColors c, String icon, String label, String value, {required bool divider}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: divider ? Border(bottom: BorderSide(color: c.divider)) : null),
        child: Row(children: [
          Container(width: 32, height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(10)), child: DcnIcon(icon, size: 16, color: c.brand)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.text)),
          ])),
        ]),
      );

  Future<void> _sms(BuildContext context, TeamWorker w) async {
    final ctrl = TextEditingController(text: 'Hi ${w.name.split(' ').first}, ');
    final send = await showDcnSheet<bool>(
      context: context,
      title: 'Send SMS',
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Goes to ${w.phone.isNotEmpty ? w.phone : 'their phone'}.', style: TextStyle(fontSize: 12.5, color: ctx.dcn.textMuted)),
          const SizedBox(height: 12),
          DcnField(label: 'Message', controller: ctrl, multiline: true),
          const SizedBox(height: 14),
          DcnButton(label: 'Send now', icon: 'send', full: true, onPressed: () => Navigator.of(ctx).pop(true)),
          const SizedBox(height: 8),
        ],
      ),
    );
    if (send == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('SMS sent to ${w.name.split(' ').first}'), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _suspend(BuildContext context, WidgetRef ref, TeamWorker w) async {
    final ctrl = TextEditingController();
    final ok = await showDcnSheet<bool>(
      context: context,
      title: 'Suspend ${w.name}?',
      builder: (ctx) {
        final c = ctx.dcn;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.dangerSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.danger.withValues(alpha: 0.4))),
              child: Text('This locks them out completely — they cannot log in until reinstated. Open tasks stay assigned; their HOD is notified.', style: TextStyle(fontSize: 12, color: c.text, height: 1.5)),
            ),
            const SizedBox(height: 12),
            DcnField(label: 'Reason (visible to their HOD)', controller: ctrl, placeholder: 'Why is this worker being suspended?', multiline: true),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: DcnButton(label: 'Cancel', variant: DcnButtonVariant.ghost, full: true, onPressed: () => Navigator.of(ctx).pop(false))),
              const SizedBox(width: 10),
              Expanded(child: DcnButton(label: 'Suspend', variant: DcnButtonVariant.danger, icon: 'lock', full: true, onPressed: () => ctrl.text.trim().isEmpty ? null : Navigator.of(ctx).pop(true))),
            ]),
            const SizedBox(height: 8),
          ],
        );
      },
    );
    if (ok == true) {
      await ref.read(pastorRepositoryProvider).setUserStatus(w.uid, suspend: true, reason: ctrl.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${w.name} suspended — app access revoked'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _reinstate(BuildContext context, WidgetRef ref, TeamWorker w) async {
    await ref.read(pastorRepositoryProvider).setUserStatus(w.uid, suspend: false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${w.name} reinstated — access restored'), behavior: SnackBarBehavior.floating));
    }
  }
}
