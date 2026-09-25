import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_scroll_scaffold.dart';
import '../../../core/widgets/dcn_sheet.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/member.dart';
import '../../../models/sms.dart';
import '../data/fu_hod_providers.dart';

// ── SMS index (the SMS tab) ──────────────────────────────────
class FuHodSmsScreen extends ConsumerWidget {
  const FuHodSmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final log = ref.watch(smsLogProvider).valueOrNull ?? const <SmsLogEntry>[];
    final auto = log.where((l) => l.auto).length;
    final manual = log.where((l) => !l.auto).length;
    final failed = log.where((l) => l.failed).length;

    Widget header(bool scrolled) => DcnHeaderBar(scrolled: scrolled, title: 'SMS engine', sub: 'Automation & broadcasts');

    return DcnScrollScaffold(
      header: header,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DcnCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${log.length}', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: c.text)),
                        Text('messages logged', style: TextStyle(fontSize: 12, color: c.textMuted)),
                      ],
                    ),
                    DcnChip(label: failed == 0 ? 'All delivered' : '$failed failed', tone: failed == 0 ? DcnTone.success : DcnTone.danger, icon: failed == 0 ? 'check' : 'alert'),
                  ],
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _MiniStat(label: 'Automated', value: auto, tone: DcnTone.brand)),
                  const SizedBox(width: 8),
                  Expanded(child: _MiniStat(label: 'Manual', value: manual, tone: DcnTone.info)),
                  const SizedBox(width: 8),
                  Expanded(child: _MiniStat(label: 'Failed', value: failed, tone: DcnTone.danger)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Tool(icon: 'settings', label: 'Absence rules', sub: 'Thresholds & templates', onTap: () => context.push('/fh/sms-rules')),
          const SizedBox(height: 8),
          _Tool(icon: 'bookOpen', label: 'Template library', sub: 'Edit automated messages', onTap: () => context.push('/fh/sms-templates')),
          const SizedBox(height: 8),
          _Tool(icon: 'send', label: 'Bulk blast', sub: 'Send to a segment', onTap: () => context.push('/fh/sms-blast')),
          const SizedBox(height: 8),
          _Tool(icon: 'list', label: 'SMS log', sub: 'Every message sent', onTap: () => context.push('/fh/sms-log')),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.tone});
  final String label;
  final int value;
  final DcnTone tone;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final fg = switch (tone) { DcnTone.brand => c.brand, DcnTone.info => c.info, DcnTone.danger => c.danger, _ => c.text };
    final bg = switch (tone) { DcnTone.brand => c.brandSoft, DcnTone.info => c.infoSoft, DcnTone.danger => c.dangerSoft, _ => c.surface2 };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text('$value', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: fg)),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, required this.sub, required this.onTap});
  final String icon;
  final String label;
  final String sub;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return DcnCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(12)), child: DcnIcon(icon, size: 20, color: c.brand)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: c.text)),
                Text(sub, style: TextStyle(fontSize: 12, color: c.textMuted)),
              ],
            ),
          ),
          DcnIcon('chevronRight', size: 20, color: c.textDim),
        ],
      ),
    );
  }
}

// ── Rules ────────────────────────────────────────────────────
class FuHodSmsRulesScreen extends ConsumerWidget {
  const FuHodSmsRulesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final rules = ref.watch(smsRulesProvider).valueOrNull ?? const <SmsRule>[];
    final sunday = rules.where((r) => r.service == 'sunday').toList();
    final tuesday = rules.where((r) => r.service == 'tuesday').toList();

    Widget rule(SmsRule r) => DcnCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: c.warningSoft, borderRadius: BorderRadius.circular(10)), child: Text('${r.threshold}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.warning))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('After ${r.threshold} misses', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text)),
                        Text(r.templateName, style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                      ],
                    ),
                  ),
                  DcnChip(label: r.active ? 'On' : 'Off', tone: r.active ? DcnTone.success : DcnTone.neutral, size: DcnButtonSize.sm),
                ],
              ),
              const SizedBox(height: 10),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(8)), child: Text(r.body, style: TextStyle(fontSize: 12, color: c.text, height: 1.4, fontStyle: FontStyle.italic))),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Absence rules', sub: 'When to auto-SMS', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  const DcnSectionHeader(title: 'Sunday · The Experience'),
                  for (final r in sunday) Padding(padding: const EdgeInsets.only(bottom: 8), child: rule(r)),
                  const DcnSectionHeader(title: 'Tuesday · Believers Equip'),
                  for (final r in tuesday) Padding(padding: const EdgeInsets.only(bottom: 8), child: rule(r)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Templates ────────────────────────────────────────────────
class FuHodSmsTemplatesScreen extends ConsumerWidget {
  const FuHodSmsTemplatesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final templates = ref.watch(smsTemplatesProvider).valueOrNull ?? const <SmsTemplate>[];
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Template library', sub: '${templates.length} templates', onBack: () => context.pop()),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final t = templates[i];
                  return DcnCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(t.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text))),
                            DcnChip(label: t.isAuto ? 'Auto' : 'Manual', tone: t.isAuto ? DcnTone.brand : DcnTone.neutral, size: DcnButtonSize.sm),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(8)),
                          child: Text(t.body.isEmpty ? '(empty — write when sending)' : t.body, style: TextStyle(fontSize: 12, color: c.text, height: 1.4, fontStyle: FontStyle.italic)),
                        ),
                        const SizedBox(height: 8),
                        DcnButton(
                          label: 'Edit',
                          variant: DcnButtonVariant.ghost,
                          size: DcnButtonSize.sm,
                          icon: 'edit',
                          onPressed: () => _edit(context, t),
                        ),
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

  Future<void> _edit(BuildContext context, SmsTemplate t) async {
    final ctrl = TextEditingController(text: t.body);
    await showDcnSheet<void>(
      context: context,
      title: t.name,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DcnField(label: 'Message', controller: ctrl, multiline: true),
          const SizedBox(height: 14),
          DcnButton(
            label: 'Save template',
            icon: 'check',
            full: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template saved'), behavior: SnackBarBehavior.floating));
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Log ──────────────────────────────────────────────────────
class FuHodSmsLogScreen extends ConsumerStatefulWidget {
  const FuHodSmsLogScreen({super.key});
  @override
  ConsumerState<FuHodSmsLogScreen> createState() => _LogState();
}

class _LogState extends ConsumerState<FuHodSmsLogScreen> {
  String _filter = 'ALL';
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final log = ref.watch(smsLogProvider).valueOrNull ?? const <SmsLogEntry>[];
    final shown = log.where((l) {
      if (_filter == 'AUTO') return l.auto;
      if (_filter == 'MANUAL') return !l.auto;
      if (_filter == 'FAILED') return l.failed;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'SMS log', sub: '${log.length} messages', onBack: () => context.pop()),
            Container(
              color: c.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: DcnSegmented(
                small: true,
                options: const [(id: 'ALL', label: 'All'), (id: 'AUTO', label: 'Auto'), (id: 'MANUAL', label: 'Manual'), (id: 'FAILED', label: 'Failed')],
                value: _filter,
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? const DcnEmptyState(icon: 'send', title: 'Nothing here', body: 'No messages in this view.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: shown.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final l = shown[i];
                        return DcnCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: l.failed ? c.dangerSoft : c.successSoft, borderRadius: BorderRadius.circular(10)), child: DcnIcon(l.failed ? 'alert' : 'check', size: 16, color: l.failed ? c.danger : c.success)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l.to, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text)),
                                    Text('${l.template} · ${l.sentAt}', style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                                    if (l.error.isNotEmpty) Text(l.error, style: TextStyle(fontSize: 11, color: c.danger)),
                                  ],
                                ),
                              ),
                              DcnChip(label: l.auto ? 'Auto' : 'Manual', tone: DcnTone.neutral, size: DcnButtonSize.sm),
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
}

// ── Bulk blast ───────────────────────────────────────────────
class FuHodSmsBlastScreen extends ConsumerStatefulWidget {
  const FuHodSmsBlastScreen({super.key});
  @override
  ConsumerState<FuHodSmsBlastScreen> createState() => _BlastState();
}

class _BlastState extends ConsumerState<FuHodSmsBlastScreen> {
  String _audience = 'all';
  final _msg = TextEditingController();

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final members = ref.watch(allMembersProvider).valueOrNull ?? const <Member>[];
    final counts = {
      'all': members.length,
      'at_risk': members.where((m) => m.isAtRisk).length,
      'first': members.where((m) => m.isFirstTimer).length,
      'unreach': members.where((m) => m.unreachable).length,
    };
    final count = counts[_audience] ?? 0;
    final sms = _msg.text.isEmpty ? 0 : (_msg.text.length / 160).ceil();
    final credits = count * (sms == 0 ? 1 : sms);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Bulk blast', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DcnSectionHeader(title: 'Audience'),
                    for (final o in [
                      (id: 'all', label: 'All members', icon: 'users'),
                      (id: 'at_risk', label: 'At-risk members', icon: 'alert'),
                      (id: 'first', label: 'First-timers', icon: 'star'),
                      (id: 'unreach', label: 'Unreachable members', icon: 'phone'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _audience = o.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(color: _audience == o.id ? c.brandSoft : c.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _audience == o.id ? c.brand : c.border, width: 1.5)),
                            child: Row(children: [
                              DcnIcon(o.icon, size: 18, color: _audience == o.id ? c.brand : c.textMuted),
                              const SizedBox(width: 12),
                              Expanded(child: Text(o.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _audience == o.id ? c.brandInk : c.text))),
                              DcnChip(label: '${counts[o.id]}', tone: _audience == o.id ? DcnTone.brand : DcnTone.neutral, size: DcnButtonSize.sm),
                            ]),
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
                          Text('${_msg.text.length} / 160 · $sms SMS/person · ~$credits credits', style: TextStyle(fontSize: 11, color: c.textDim)),
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
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Blast queued to $count people'), behavior: SnackBarBehavior.floating));
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
