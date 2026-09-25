import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_sheet.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/life_update.dart';
import '../data/worker_providers.dart';

const _types = <({LifeUpdateType type, String label, String icon, DcnTone tone})>[
  (type: LifeUpdateType.testimony, label: 'Testimony', icon: 'sparkle', tone: DcnTone.success),
  (type: LifeUpdateType.prayerNeed, label: 'Prayer need', icon: 'bookOpen', tone: DcnTone.brand),
  (type: LifeUpdateType.struggle, label: 'Struggle', icon: 'alertCircle', tone: DcnTone.warning),
  (type: LifeUpdateType.milestone, label: 'Milestone', icon: 'award', tone: DcnTone.info),
];

({String icon, DcnTone tone}) _visual(LifeUpdateType t) {
  final m = _types.firstWhere((x) => x.type == t);
  return (icon: m.icon, tone: m.tone);
}

class WorkerLifeScreen extends ConsumerWidget {
  const WorkerLifeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final async = ref.watch(workerLifeUpdatesProvider);
    final items = async.valueOrNull ?? const <LifeUpdate>[];

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(
              title: 'Life updates',
              sub: 'Share what God is doing',
              onBack: () => context.pop(),
              right: [
                DcnButton(
                  label: 'Share',
                  size: DcnButtonSize.sm,
                  icon: 'plus',
                  onPressed: () => _openCompose(context, ref),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.brandSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "Life updates go straight to your HOD (and Pastor, if you choose). It's how leadership prays with you, celebrates with you, and knows when to check in.",
                      style: TextStyle(fontSize: 12.5, color: c.brandInk, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (async.isLoading && !async.hasValue)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (items.isEmpty)
                    const DcnEmptyState(
                      icon: 'bookOpen',
                      title: 'Nothing shared yet',
                      body: 'Tap Share to send your first update.',
                    )
                  else
                    for (final u in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LifeCard(u: u),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCompose(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final deptCode = ref.read(authStateProvider).valueOrNull?.departmentCode;
    final body = TextEditingController();
    var type = LifeUpdateType.testimony;
    var share = 'My HOD + Pastor';
    var busy = false;

    await showDcnSheet<void>(
      context: context,
      title: 'Share a life update',
      builder: (ctx) {
        final c = ctx.dcn;
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Future<void> submit() async {
              if (body.text.trim().isEmpty) return;
              setSheet(() => busy = true);
              try {
                await ref.read(workerRepositoryProvider).createLifeUpdate(
                      uid,
                      type: type.label,
                      body: body.text,
                      sharedWith: share,
                      departmentCode: deptCode,
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Shared with your leaders 🙏'),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } catch (_) {
                setSheet(() => busy = false);
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in _types)
                      GestureDetector(
                        onTap: () => setSheet(() => type = t.type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: type == t.type ? c.brandSoft : c.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: type == t.type ? c.brand : c.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DcnIcon(t.icon, size: 14, color: type == t.type ? c.brandInk : c.textMuted),
                              const SizedBox(width: 6),
                              Text(t.label,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: type == t.type ? c.brandInk : c.textMuted)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                DcnField(
                  label: 'What would you like to share?',
                  controller: body,
                  placeholder: 'Write freely — your leaders will read this.',
                  multiline: true,
                ),
                const SizedBox(height: 14),
                Text('Share with', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final s in const ['My HOD', 'My HOD + Pastor'])
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: s == 'My HOD' ? 8 : 0),
                          child: GestureDetector(
                            onTap: () => setSheet(() => share = s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: share == s ? c.brandSoft : c.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: share == s ? c.brand : c.border),
                              ),
                              child: Text(s,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: share == s ? c.brandInk : c.textMuted)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                DcnButton(
                  label: busy ? 'Sharing…' : 'Share update',
                  icon: 'send',
                  full: true,
                  loading: busy,
                  onPressed: busy ? null : submit,
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }
}

class _LifeCard extends StatelessWidget {
  const _LifeCard({required this.u});
  final LifeUpdate u;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final v = _visual(u.type);
    return DcnCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DcnChip(label: u.type.label, tone: v.tone, icon: v.icon, size: DcnButtonSize.sm),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${u.atLabel} · ${u.sharedWith}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: c.textDim)),
              ),
              Text(u.responded ? 'Responded' : 'Seen',
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: u.responded ? c.success : c.textDim)),
            ],
          ),
          const SizedBox(height: 8),
          Text(u.body, style: TextStyle(fontSize: 13, color: c.text, height: 1.5)),
          if (u.response != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: c.brand, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${u.response!.by} · ${u.response!.at}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.brand)),
                  const SizedBox(height: 3),
                  Text(u.response!.body, style: TextStyle(fontSize: 12.5, color: c.text)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
