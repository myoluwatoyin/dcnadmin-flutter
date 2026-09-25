import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/team_worker.dart';
import '../data/hod_providers.dart';

// ── New meeting ──────────────────────────────────────────────
class HodNewMeetingScreen extends ConsumerStatefulWidget {
  const HodNewMeetingScreen({super.key});
  @override
  ConsumerState<HodNewMeetingScreen> createState() => _NewState();
}

class _NewState extends ConsumerState<HodNewMeetingScreen> {
  final _title = TextEditingController();
  final _date = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _location = TextEditingController();
  final _agenda = TextEditingController();
  String _type = 'REGULAR';
  bool _recurring = false;
  bool _notifySms = true;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final team = ref.watch(hodTeamProvider).valueOrNull ?? const <TeamWorker>[];
    final dept = ref.watch(hodDeptProvider);
    final valid = _title.text.trim().isNotEmpty && _date.text.trim().isNotEmpty && _start.text.trim().isNotEmpty;

    Future<void> submit() async {
      if (dept == null) return;
      setState(() => _busy = true);
      try {
        await ref.read(hodRepositoryProvider).createMeeting(
              dept: dept,
              title: _title.text,
              type: _type,
              date: _date.text,
              start: _start.text,
              end: _end.text,
              location: _location.text,
              agenda: _agenda.text,
              audienceUids: team.map((w) => w.uid).toList(),
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Meeting created · ${team.length} notified'),
            behavior: SnackBarBehavior.floating,
          ));
          context.pop();
        }
      } catch (_) {
        if (mounted) setState(() => _busy = false);
      }
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'New meeting', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DcnField(label: 'Meeting title', controller: _title, placeholder: 'e.g. Weekly rehearsal', onChanged: (_) => setState(() {})),
                    const SizedBox(height: 14),
                    Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final t in const [
                          (id: 'REGULAR', label: 'Regular', icon: 'calendar', tone: DcnTone.brand),
                          (id: 'AD_HOC', label: 'One-off', icon: 'clock', tone: DcnTone.info),
                          (id: 'EMERGENCY', label: 'Emergency', icon: 'alert', tone: DcnTone.danger),
                        ])
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: t.id == 'EMERGENCY' ? 0 : 8),
                              child: _TypeCard(
                                icon: t.icon,
                                label: t.label,
                                tone: t.tone,
                                active: _type == t.id,
                                onTap: () => setState(() => _type = t.id),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(flex: 3, child: DcnField(label: 'Date', controller: _date, icon: 'calendar', placeholder: 'Thu, 21 May', onChanged: (_) => setState(() {}))),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: DcnField(label: 'Start', controller: _start, placeholder: '5:00 PM', onChanged: (_) => setState(() {}))),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: DcnField(label: 'End', controller: _end, placeholder: '8:00 PM')),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DcnField(label: 'Location', controller: _location, icon: 'location', placeholder: 'e.g. Hall B'),
                    const SizedBox(height: 14),
                    DcnField(label: 'Agenda', controller: _agenda, placeholder: "What you'll cover…", multiline: true),
                    const DcnSectionHeader(title: 'Options'),
                    DcnCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              DcnIcon('refresh', size: 18, color: c.brand),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Make this recurring', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text))),
                              DcnToggle(value: _recurring, onChanged: (v) => setState(() => _recurring = v)),
                            ],
                          ),
                          Divider(color: c.divider, height: 24),
                          Row(
                            children: [
                              DcnIcon('msg', size: 18, color: c.brand),
                              const SizedBox(width: 12),
                              Expanded(child: Text('SMS to everyone', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text))),
                              DcnToggle(value: _notifySms, onChanged: (v) => setState(() => _notifySms = v)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Whole department (${team.length}) will be invited.',
                        style: TextStyle(fontSize: 12, color: c.textDim)),
                  ],
                ),
              ),
            ),
            _bottomBar(context, DcnButton(label: _busy ? 'Creating…' : 'Create & notify', icon: 'send', size: DcnButtonSize.lg, full: true, loading: _busy, onPressed: valid && !_busy ? submit : null)),
          ],
        ),
      ),
    );
  }
}

// ── Reschedule ───────────────────────────────────────────────
class HodRescheduleScreen extends ConsumerStatefulWidget {
  const HodRescheduleScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<HodRescheduleScreen> createState() => _ReState();
}

class _ReState extends ConsumerState<HodRescheduleScreen> {
  final _date = TextEditingController();
  final _start = TextEditingController();
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final m = ref.watch(hodMeetingByIdProvider(widget.id));
    if (m == null) {
      return Scaffold(backgroundColor: c.bg, body: SafeArea(child: Column(children: [DcnHeaderBar(title: 'Reschedule', onBack: () => context.pop()), const Expanded(child: DcnEmptyState(icon: 'calendar', title: 'Not found', body: ''))])));
    }
    final valid = _date.text.trim().isNotEmpty && _start.text.trim().isNotEmpty;

    Future<void> submit() async {
      setState(() => _busy = true);
      try {
        await ref.read(hodRepositoryProvider).rescheduleMeeting(widget.id, newDate: _date.text, newStart: _start.text, reason: _reason.text);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rescheduled · team notified'), behavior: SnackBarBehavior.floating));
          context.pop();
        }
      } catch (_) {
        if (mounted) setState(() => _busy = false);
      }
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Reschedule', sub: m.title, onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DcnCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CURRENTLY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.textMuted, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text('${m.date} · ${m.start}${m.end.isNotEmpty ? ' – ${m.end}' : ''}',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.text)),
                          if (m.location.isNotEmpty) Text(m.location, style: TextStyle(fontSize: 12, color: c.textMuted)),
                        ],
                      ),
                    ),
                    const DcnSectionHeader(title: 'New date & time'),
                    DcnField(label: 'New date', controller: _date, icon: 'calendar', placeholder: 'Sat, 23 May', onChanged: (_) => setState(() {})),
                    const SizedBox(height: 12),
                    DcnField(label: 'New start time', controller: _start, placeholder: '9:00 AM', onChanged: (_) => setState(() {})),
                    const DcnSectionHeader(title: 'Why?'),
                    DcnField(controller: _reason, placeholder: 'Workers will see this in the notification', multiline: true, hint: 'Optional but recommended.'),
                  ],
                ),
              ),
            ),
            _bottomBar(context, DcnButton(label: _busy ? 'Saving…' : 'Confirm reschedule', icon: 'send', size: DcnButtonSize.lg, full: true, loading: _busy, onPressed: valid && !_busy ? submit : null)),
          ],
        ),
      ),
    );
  }
}

// ── Cancel ───────────────────────────────────────────────────
class HodCancelMeetingScreen extends ConsumerStatefulWidget {
  const HodCancelMeetingScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<HodCancelMeetingScreen> createState() => _CancelState();
}

class _CancelState extends ConsumerState<HodCancelMeetingScreen> {
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final m = ref.watch(hodMeetingByIdProvider(widget.id));
    if (m == null) {
      return Scaffold(backgroundColor: c.bg, body: SafeArea(child: Column(children: [DcnHeaderBar(title: 'Cancel meeting', onBack: () => context.pop()), const Expanded(child: DcnEmptyState(icon: 'calendar', title: 'Not found', body: ''))])));
    }

    Future<void> submit() async {
      setState(() => _busy = true);
      try {
        await ref.read(hodRepositoryProvider).cancelMeeting(widget.id, _reason.text);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meeting cancelled · team notified'), behavior: SnackBarBehavior.floating));
          context.pop();
        }
      } catch (_) {
        if (mounted) setState(() => _busy = false);
      }
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Cancel meeting', sub: m.title, onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: c.dangerSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.danger.withValues(alpha: 0.4))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DcnIcon('alert', size: 18, color: c.danger),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cancelling will notify everyone', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.danger)),
                                const SizedBox(height: 3),
                                Text('It stays in history with status "Cancelled" for audit.', style: TextStyle(fontSize: 12, color: c.text)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    DcnField(label: 'Reason', controller: _reason, placeholder: 'Why is this being cancelled?', multiline: true, hint: 'Workers will see this in their notification.'),
                  ],
                ),
              ),
            ),
            _bottomBar(
              context,
              Row(children: [
                Expanded(child: DcnButton(label: 'Keep meeting', variant: DcnButtonVariant.ghost, full: true, onPressed: () => context.pop())),
                const SizedBox(width: 10),
                Expanded(child: DcnButton(label: 'Cancel & notify', variant: DcnButtonVariant.danger, icon: 'x', full: true, loading: _busy, onPressed: _busy ? null : submit)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── shared ───────────────────────────────────────────────────
Widget _bottomBar(BuildContext context, Widget child) {
  final c = context.dcn;
  return Container(
    decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    child: child,
  );
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.icon, required this.label, required this.tone, required this.active, required this.onTap});
  final String icon;
  final String label;
  final DcnTone tone;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final fg = switch (tone) {
      DcnTone.info => c.info,
      DcnTone.danger => c.danger,
      _ => c.brand,
    };
    final bg = switch (tone) {
      DcnTone.info => c.infoSoft,
      DcnTone.danger => c.dangerSoft,
      _ => c.brandSoft,
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? bg : c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? fg : c.border, width: 1.5),
        ),
        child: Column(
          children: [
            DcnIcon(icon, size: 18, color: active ? fg : c.text),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? fg : c.text)),
          ],
        ),
      ),
    );
  }
}
