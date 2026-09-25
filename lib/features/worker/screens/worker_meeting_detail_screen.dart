import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/meeting.dart';
import '../data/worker_providers.dart';
import '../widgets/worker_rows.dart';

/// Meeting detail: gradient hero, when/where, reschedule banner, agenda,
/// reminder toggle and RSVP. RSVP/reminder are local for this slice (no write
/// path yet); the schedule read is live.
class WorkerMeetingDetailScreen extends ConsumerStatefulWidget {
  const WorkerMeetingDetailScreen({super.key, required this.meetingId});
  final String meetingId;

  @override
  ConsumerState<WorkerMeetingDetailScreen> createState() => _State();
}

class _State extends ConsumerState<WorkerMeetingDetailScreen> {
  String? _rsvp;
  bool _remind = true;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final m = ref.watch(workerMeetingByIdProvider(widget.meetingId));

    if (m == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(
            children: [
              DcnHeaderBar(title: 'Meeting', onBack: () => context.pop()),
              const Expanded(
                child: DcnEmptyState(
                    icon: 'calendar', title: 'Meeting not found', body: 'It may have been cancelled.'),
              ),
            ],
          ),
        ),
      );
    }

    final tone = meetingTone(m);
    final heroColors = switch (tone) {
      DcnTone.danger => [const Color(0xFFF87171), const Color(0xFFDC2626)],
      DcnTone.warning => [const Color(0xFFFBBF24), const Color(0xFFD97706)],
      DcnTone.info => [const Color(0xFF60A5FA), const Color(0xFF2563EB)],
      _ => [c.brand, c.brandDeep],
    };
    final typeLabel = switch (m.type) {
      MeetingType.emergency => 'EMERGENCY',
      MeetingType.adHoc => 'AD-HOC',
      MeetingType.service => 'SERVICE',
      MeetingType.regular => 'REGULAR',
    };

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Meeting', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // hero
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: heroColors,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            children: [
                              _HeroPill(typeLabel),
                              if (m.status == MeetingStatus.rescheduled) _HeroPill('RESCHEDULED'),
                              if (m.status == MeetingStatus.cancelled) _HeroPill('CANCELLED'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(m.title,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.2,
                                  letterSpacing: -0.4)),
                        ],
                      ),
                    ),
                    const DcnSectionHeader(title: 'When & where'),
                    DcnCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _InfoRow(icon: 'calendar', label: 'DATE', value: m.date, divider: true),
                          _InfoRow(
                              icon: 'clock',
                              label: 'TIME',
                              value: '${m.start}${m.end.isNotEmpty ? ' – ${m.end}' : ''}',
                              divider: true),
                          _InfoRow(
                              icon: 'location',
                              label: 'LOCATION',
                              value: m.location.isNotEmpty ? m.location : '—'),
                        ],
                      ),
                    ),
                    if (m.status == MeetingStatus.rescheduled && (m.reason ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.warningSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.warning.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DcnIcon('alert', size: 20, color: c.warning),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Why was this moved?',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: c.warning)),
                                  const SizedBox(height: 3),
                                  Text(m.reason!,
                                      style: TextStyle(fontSize: 12.5, color: c.text)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if ((m.agenda ?? '').isNotEmpty) ...[
                      const DcnSectionHeader(title: 'Agenda'),
                      DcnCard(
                        child: Text(m.agenda!,
                            style: TextStyle(fontSize: 13, color: c.text, height: 1.55)),
                      ),
                    ],
                    const DcnSectionHeader(title: 'Notify me'),
                    DcnCard(
                      child: Row(
                        children: [
                          DcnIcon('bell', size: 18, color: c.brand),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('1 hour before',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: c.text)),
                          ),
                          DcnToggle(value: _remind, onChanged: (v) => setState(() => _remind = v)),
                        ],
                      ),
                    ),
                    if (m.status != MeetingStatus.cancelled) ...[
                      const DcnSectionHeader(title: 'Are you coming?'),
                      Row(
                        children: [
                          _RsvpButton(
                            label: "I'll be there",
                            icon: 'check',
                            tone: DcnTone.success,
                            active: _rsvp == 'yes',
                            onTap: () => _setRsvp('yes', 'Marked attending'),
                          ),
                          const SizedBox(width: 8),
                          _RsvpButton(
                            label: 'Maybe',
                            icon: 'clock',
                            tone: DcnTone.warning,
                            active: _rsvp == 'maybe',
                            onTap: () => _setRsvp('maybe', 'Marked maybe'),
                          ),
                          const SizedBox(width: 8),
                          _RsvpButton(
                            label: "Can't make it",
                            icon: 'x',
                            tone: DcnTone.danger,
                            active: _rsvp == 'no',
                            onTap: () => _setRsvp('no', 'Sent regrets to HOD'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setRsvp(String v, String msg) {
    setState(() => _rsvp = v);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.divider = false,
  });
  final String icon;
  final String label;
  final String value;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: c.divider)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(10)),
            child: DcnIcon(icon, size: 18, color: c.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.textMuted,
                        letterSpacing: 0.5)),
                const SizedBox(height: 3),
                Text(value,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RsvpButton extends StatelessWidget {
  const _RsvpButton({
    required this.label,
    required this.icon,
    required this.tone,
    required this.active,
    required this.onTap,
  });
  final String label;
  final String icon;
  final DcnTone tone;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final ({Color bg, Color fg}) t = switch (tone) {
      DcnTone.success => (bg: c.successSoft, fg: c.success),
      DcnTone.warning => (bg: c.warningSoft, fg: c.warning),
      DcnTone.danger => (bg: c.dangerSoft, fg: c.danger),
      _ => (bg: c.brandSoft, fg: c.brand),
    };
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: active ? t.bg : c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? t.fg : c.border, width: 1.5),
          ),
          child: Column(
            children: [
              DcnIcon(icon, size: 18, color: active ? t.fg : c.text),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: active ? t.fg : c.text)),
            ],
          ),
        ),
      ),
    );
  }
}
