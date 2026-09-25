import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_sheet.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/invite_code.dart';
import '../data/pastor_providers.dart';

class PastorAccessKeysScreen extends ConsumerWidget {
  const PastorAccessKeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final codes = ref.watch(inviteCodesProvider).valueOrNull ?? const <InviteCode>[];

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(
              title: 'Invite codes',
              sub: 'Generate & manage sign-up codes',
              onBack: () => context.pop(),
              right: [DcnButton(label: 'New', size: DcnButtonSize.sm, icon: 'plus', onPressed: () => _generate(context, ref))],
            ),
            Expanded(
              child: codes.isEmpty
                  ? const DcnEmptyState(icon: 'lock', title: 'No invite codes', body: 'Generate a code to onboard workers.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: codes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final k = codes[i];
                        final tone = k.status == 'ACTIVE' ? DcnTone.success : k.status == 'EXHAUSTED' ? DcnTone.neutral : DcnTone.danger;
                        return DcnCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(child: Text(k.code, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.text, fontFamily: 'monospace', letterSpacing: 0.4))),
                                DcnChip(label: '${k.status[0]}${k.status.substring(1).toLowerCase()}', tone: tone, size: DcnButtonSize.sm),
                              ]),
                              const SizedBox(height: 4),
                              Text('${_roleLabel(k.role)} · ${k.departmentName} · ${k.usesLeft}/${k.usesTotal} left · exp ${k.expires}', style: TextStyle(fontSize: 11, color: c.textMuted)),
                              if (k.status == 'ACTIVE') ...[
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(child: DcnButton(
                                    label: 'Copy',
                                    variant: DcnButtonVariant.secondary,
                                    size: DcnButtonSize.sm,
                                    icon: 'clipboard',
                                    full: true,
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: k.code));
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied ${k.code}'), behavior: SnackBarBehavior.floating));
                                    },
                                  )),
                                  const SizedBox(width: 8),
                                  Expanded(child: DcnButton(
                                    label: 'Revoke',
                                    variant: DcnButtonVariant.ghost,
                                    size: DcnButtonSize.sm,
                                    icon: 'x',
                                    full: true,
                                    onPressed: () async {
                                      await ref.read(pastorRepositoryProvider).revokeInviteCode(k.id);
                                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite code revoked'), behavior: SnackBarBehavior.floating));
                                    },
                                  )),
                                ]),
                              ],
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

  String _roleLabel(String r) => switch (r.toUpperCase()) { 'HOD' => 'HOD', 'SUBHOD' => 'Sub-HOD', _ => 'Worker' };

  Future<void> _generate(BuildContext context, WidgetRef ref) async {
    var role = 'WORKER';
    var dept = 'Drama';
    var uses = 10.0;
    const depts = ['Worship', 'Media', 'Ushering', 'Drama', 'Technical', 'Follow-Up'];

    final made = await showDcnSheet<bool>(
      context: context,
      title: 'Generate invite code',
      builder: (ctx) {
        final c = ctx.dcn;
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted)),
              const SizedBox(height: 6),
              Row(children: [
                for (final r in const [(id: 'WORKER', label: 'Worker'), (id: 'SUBHOD', label: 'Sub-HOD'), (id: 'HOD', label: 'HOD')])
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: r.id == 'HOD' ? 0 : 8),
                      child: GestureDetector(
                        onTap: () => setSheet(() => role = r.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: role == r.id ? c.brandSoft : c.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: role == r.id ? c.brand : c.border)),
                          child: Text(r.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: role == r.id ? c.brandInk : c.textMuted)),
                        ),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 14),
              Text('Department', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final d in depts)
                  GestureDetector(
                    onTap: () => setSheet(() => dept = d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: dept == d ? c.brandSoft : c.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: dept == d ? c.brand : c.border)),
                      child: Text(d, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dept == d ? c.brandInk : c.textMuted)),
                    ),
                  ),
              ]),
              const SizedBox(height: 14),
              Text('Number of uses · ${uses.round()}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted)),
              Slider(value: uses, min: 1, max: 50, divisions: 49, activeColor: c.brand, onChanged: (v) => setSheet(() => uses = v)),
              const SizedBox(height: 6),
              DcnButton(label: 'Generate code', icon: 'plus', full: true, onPressed: () => Navigator.of(ctx).pop(true)),
              const SizedBox(height: 8),
            ],
          );
        });
      },
    );

    if (made == true) {
      final rand = DateTime.now().microsecondsSinceEpoch.toRadixString(36).toUpperCase().substring(0, 4);
      final code = 'DCN-${role.substring(0, 3)}-$rand';
      await ref.read(pastorRepositoryProvider).createInviteCode(code: code, role: role, departmentName: dept, uses: uses.round());
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generated $code'), behavior: SnackBarBehavior.floating));
    }
  }
}
