import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_sheet.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/life_update.dart';
import '../data/hod_providers.dart';

DcnTone _tone(LifeUpdateType t) => switch (t) {
      LifeUpdateType.testimony => DcnTone.success,
      LifeUpdateType.prayerNeed => DcnTone.brand,
      LifeUpdateType.struggle => DcnTone.warning,
      LifeUpdateType.milestone => DcnTone.info,
    };
String _icon(LifeUpdateType t) => switch (t) {
      LifeUpdateType.testimony => 'sparkle',
      LifeUpdateType.prayerNeed => 'bookOpen',
      LifeUpdateType.struggle => 'alertCircle',
      LifeUpdateType.milestone => 'award',
    };

class HodLifeInboxScreen extends ConsumerStatefulWidget {
  const HodLifeInboxScreen({super.key});
  @override
  ConsumerState<HodLifeInboxScreen> createState() => _State();
}

class _State extends ConsumerState<HodLifeInboxScreen> {
  String _filter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final all = ref.watch(hodLifeInboxProvider).valueOrNull ?? const <LifeUpdate>[];
    final newCount = all.where((u) => !u.responded).length;
    final shown = _filter == 'NEW' ? all.where((u) => !u.responded).toList() : all;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Life updates', sub: '$newCount awaiting response', onBack: () => context.pop()),
            Container(
              color: c.surface,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: DcnSegmented(
                small: true,
                options: [(id: 'ALL', label: 'All (${all.length})'), (id: 'NEW', label: 'New ($newCount)')],
                value: _filter,
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? const DcnEmptyState(icon: 'checkCircle', title: 'All responded', body: 'No updates awaiting your reply.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: shown.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _Card(u: shown[i], onRespond: () => _respond(shown[i])),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respond(LifeUpdate u) async {
    final by = ref.read(authStateProvider).valueOrNull?.fullName ?? 'HOD';
    final text = TextEditingController();
    final sent = await showDcnSheet<bool>(
      context: context,
      title: 'Respond',
      builder: (ctx) {
        final c = ctx.dcn;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(12)),
              child: Text(u.body, style: TextStyle(fontSize: 12.5, color: c.textMuted, height: 1.5)),
            ),
            const SizedBox(height: 12),
            DcnField(label: 'Your response', controller: text, placeholder: 'Encourage, pray, or offer to meet…', multiline: true),
            const SizedBox(height: 14),
            DcnButton(label: 'Send response', icon: 'send', full: true, onPressed: () => Navigator.of(ctx).pop(true)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
    if (sent == true && text.text.trim().isNotEmpty) {
      await ref.read(hodRepositoryProvider).respondLifeUpdate(u.id, by: by, body: text.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Response sent'), behavior: SnackBarBehavior.floating));
      }
    }
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.u, required this.onRespond});
  final LifeUpdate u;
  final VoidCallback onRespond;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return DcnCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DcnAvatar(name: u.workerName.isNotEmpty ? u.workerName : 'Worker', size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.workerName.isNotEmpty ? u.workerName : 'Worker',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
                    Text(u.atLabel, style: TextStyle(fontSize: 11, color: c.textMuted)),
                  ],
                ),
              ),
              DcnChip(label: u.type.label, tone: _tone(u.type), icon: _icon(u.type), size: DcnButtonSize.sm),
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
                  Text('You replied · ${u.response!.at}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.brand)),
                  const SizedBox(height: 3),
                  Text(u.response!.body, style: TextStyle(fontSize: 12.5, color: c.text)),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: DcnButton(label: 'Respond', variant: DcnButtonVariant.secondary, size: DcnButtonSize.sm, icon: 'msg', full: true, onPressed: onRespond)),
                const SizedBox(width: 8),
                DcnButton(
                  label: 'Praying',
                  variant: DcnButtonVariant.ghost,
                  size: DcnButtonSize.sm,
                  icon: 'bookOpen',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Praying for ${u.workerName.split(' ').first} 🙏'), behavior: SnackBarBehavior.floating),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
