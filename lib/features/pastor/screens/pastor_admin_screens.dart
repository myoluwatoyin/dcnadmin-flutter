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
import '../data/pastor_providers.dart';

// ── Life-updates inbox (church-wide) ─────────────────────────
class PastorLifeInboxScreen extends ConsumerStatefulWidget {
  const PastorLifeInboxScreen({super.key});
  @override
  ConsumerState<PastorLifeInboxScreen> createState() => _LifeState();
}

class _LifeState extends ConsumerState<PastorLifeInboxScreen> {
  String _filter = 'ALL';

  DcnTone _tone(LifeUpdateType t) => switch (t) {
        LifeUpdateType.testimony => DcnTone.success,
        LifeUpdateType.prayerNeed => DcnTone.brand,
        LifeUpdateType.struggle => DcnTone.warning,
        LifeUpdateType.milestone => DcnTone.info,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final all = ref.watch(pastorLifeInboxProvider).valueOrNull ?? const <LifeUpdate>[];
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
              child: DcnSegmented(small: true, options: [(id: 'ALL', label: 'All (${all.length})'), (id: 'NEW', label: 'New ($newCount)')], value: _filter, onChanged: (v) => setState(() => _filter = v)),
            ),
            Expanded(
              child: shown.isEmpty
                  ? const DcnEmptyState(icon: 'checkCircle', title: 'All responded', body: 'No updates awaiting your reply.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: shown.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final u = shown[i];
                        return DcnCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                DcnAvatar(name: u.workerName.isNotEmpty ? u.workerName : 'Worker', size: 36),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(u.workerName.isNotEmpty ? u.workerName : 'Worker', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
                                  Text(u.atLabel, style: TextStyle(fontSize: 11, color: c.textMuted)),
                                ])),
                                DcnChip(label: u.type.label, tone: _tone(u.type), size: DcnButtonSize.sm),
                              ]),
                              const SizedBox(height: 8),
                              Text(u.body, style: TextStyle(fontSize: 13, color: c.text, height: 1.5)),
                              if (u.response != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: c.brand, width: 3))),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('${u.response!.by} · ${u.response!.at}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.brand)),
                                    const SizedBox(height: 3),
                                    Text(u.response!.body, style: TextStyle(fontSize: 12.5, color: c.text)),
                                  ]),
                                ),
                              ] else ...[
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(child: DcnButton(label: 'Respond', variant: DcnButtonVariant.secondary, size: DcnButtonSize.sm, icon: 'msg', full: true, onPressed: () => _respond(u))),
                                  const SizedBox(width: 8),
                                  DcnButton(label: 'Praying', variant: DcnButtonVariant.ghost, size: DcnButtonSize.sm, icon: 'bookOpen', onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Praying for ${u.workerName.split(' ').first} 🙏'), behavior: SnackBarBehavior.floating))),
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

  Future<void> _respond(LifeUpdate u) async {
    final by = ref.read(authStateProvider).valueOrNull?.fullName ?? 'Pastor';
    final text = TextEditingController();
    final sent = await showDcnSheet<bool>(
      context: context,
      title: 'Respond',
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: ctx.dcn.surface2, borderRadius: BorderRadius.circular(12)), child: Text(u.body, style: TextStyle(fontSize: 12.5, color: ctx.dcn.textMuted, height: 1.5))),
          const SizedBox(height: 12),
          DcnField(label: 'Your response', controller: text, placeholder: 'Encourage, pray, or offer to meet…', multiline: true),
          const SizedBox(height: 14),
          DcnButton(label: 'Send response', icon: 'send', full: true, onPressed: () => Navigator.of(ctx).pop(true)),
          const SizedBox(height: 8),
        ],
      ),
    );
    if (sent == true && text.text.trim().isNotEmpty) {
      await ref.read(pastorRepositoryProvider).respondLifeUpdate(u.id, by: by, body: text.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Response sent'), behavior: SnackBarBehavior.floating));
    }
  }
}

// ── System settings ──────────────────────────────────────────
const _settings = <({String group, String icon, String label, String value, String? desc, bool toggle})>[
  (group: 'Services', icon: 'calendar', label: 'Sunday service name', value: 'The Experience', desc: null, toggle: false),
  (group: 'Services', icon: 'calendar', label: 'Midweek service name', value: 'Believers Equip', desc: null, toggle: false),
  (group: 'SMS engine', icon: 'send', label: 'Sunday absence threshold', value: '2', desc: 'Consecutive Sundays missed before auto-SMS', toggle: false),
  (group: 'SMS engine', icon: 'send', label: 'Tuesday absence threshold', value: '3', desc: 'Consecutive Tuesdays missed before auto-SMS', toggle: false),
  (group: 'SMS engine', icon: 'send', label: 'SMS sender name', value: 'DCN', desc: null, toggle: false),
  (group: 'Assessment', icon: 'award', label: 'Scorecard pass mark', value: '50', desc: 'Out of 100, across 5 components', toggle: false),
  (group: 'Follow-up', icon: 'phone', label: 'First-timer auto-assign', value: 'On', desc: 'Round-robin new first-timers to FU workers', toggle: true),
  (group: 'Follow-up', icon: 'phone', label: 'Report deadline', value: 'Thursday', desc: 'Weekly follow-up report due day', toggle: false),
];

class PastorSettingsScreen extends StatefulWidget {
  const PastorSettingsScreen({super.key});
  @override
  State<PastorSettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<PastorSettingsScreen> {
  final Map<String, String> _values = {for (final s in _settings) s.label: s.value};

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final groups = <String>[];
    for (final s in _settings) {
      if (!groups.contains(s.group)) groups.add(s.group);
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'System settings', sub: 'Church-wide · Pastor only', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: c.warningSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.warning.withValues(alpha: 0.4))),
                    child: Text('These values drive automation church-wide — absence SMS, pass marks, service names. Changes take effect immediately.', style: TextStyle(fontSize: 12, color: c.text, height: 1.5)),
                  ),
                  for (final g in groups) ...[
                    DcnSectionHeader(title: g),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: DcnCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            for (final s in _settings.where((x) => x.group == g))
                              _rowFor(c, s),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const DcnSectionHeader(title: 'Integrations'),
                  DcnCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(children: [
                      for (final it in const [('Termii SMS', 'Connected', DcnTone.success), ('Firebase Auth', 'Connected', DcnTone.success), ('Cloud Storage', 'Connected', DcnTone.success), ('Google Forms', 'Not linked', DcnTone.neutral)])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(children: [
                            Expanded(child: Text(it.$1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text))),
                            DcnChip(label: it.$2, tone: it.$3, size: DcnButtonSize.sm),
                          ]),
                        ),
                    ]),
                  ),
                  const DcnSectionHeader(title: 'Danger zone'),
                  DcnCard(
                    child: Column(children: [
                      DcnButton(label: 'Start new assessment period', variant: DcnButtonVariant.ghost, icon: 'refresh', full: true, onPressed: () => _toast(context, 'Confirm flow — new assessment period')),
                      const SizedBox(height: 6),
                      DcnButton(label: 'Archive year & roll over', variant: DcnButtonVariant.ghost, icon: 'alert', full: true, onPressed: () => _toast(context, 'Confirm flow — year-end roll-over')),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowFor(DcnColors c, ({String group, String icon, String label, String value, String? desc, bool toggle}) s) {
    final isOn = _values[s.label] == 'On';
    return InkWell(
      onTap: s.toggle ? () => setState(() => _values[s.label] = isOn ? 'Off' : 'On') : () => _edit(c, s),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(width: 32, height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(10)), child: DcnIcon(s.icon, size: 16, color: c.brand)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
                  if (s.desc != null) ...[const SizedBox(height: 2), Text(s.desc!, style: TextStyle(fontSize: 11, color: c.textDim))],
                ],
              ),
            ),
            if (s.toggle)
              DcnToggle(value: isOn, onChanged: (v) => setState(() => _values[s.label] = v ? 'On' : 'Off'))
            else
              Row(children: [
                Text(_values[s.label] ?? s.value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.brand)),
                DcnIcon('chevronRight', size: 14, color: c.textDim),
              ]),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(DcnColors c, ({String group, String icon, String label, String value, String? desc, bool toggle}) s) async {
    final ctrl = TextEditingController(text: _values[s.label]);
    final saved = await showDcnSheet<bool>(
      context: context,
      title: 'Edit · ${s.label}',
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.desc != null) Text(s.desc!, style: TextStyle(fontSize: 12, color: ctx.dcn.textMuted, height: 1.5)),
          const SizedBox(height: 12),
          DcnField(label: s.label, controller: ctrl),
          const SizedBox(height: 14),
          DcnButton(label: 'Save', icon: 'check', full: true, onPressed: () => Navigator.of(ctx).pop(true)),
          const SizedBox(height: 8),
        ],
      ),
    );
    if (saved == true) {
      setState(() => _values[s.label] = ctrl.text);
      if (mounted) _toast(context, '${s.label} updated');
    }
  }

  void _toast(BuildContext context, String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
}
