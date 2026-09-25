import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/meeting.dart';
import '../../worker/widgets/worker_rows.dart';
import '../data/hod_providers.dart';

/// HOD's admin view of a meeting: hero, when/where, change log, agenda, and
/// reschedule/cancel actions. RSVP totals appear as the team responds.
class HodMeetingDetailScreen extends ConsumerWidget {
  const HodMeetingDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final m = ref.watch(hodMeetingByIdProvider(id));

    if (m == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(children: [
            DcnHeaderBar(title: 'Meeting', onBack: () => context.pop()),
            const Expanded(child: DcnEmptyState(icon: 'calendar', title: 'Not found', body: 'This meeting no longer exists.')),
          ]),
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
    final active = m.status == MeetingStatus.scheduled || m.status == MeetingStatus.rescheduled;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Meeting', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: heroColors),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(spacing: 8, children: [
                            _pill(m.type.name.toUpperCase()),
                            if (m.status != MeetingStatus.scheduled) _pill(m.status.name.toUpperCase()),
                          ]),
                          const SizedBox(height: 12),
                          Text(m.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
                          const SizedBox(height: 8),
                          Text('${m.date} · ${m.start}${m.end.isNotEmpty ? ' – ${m.end}' : ''}',
                              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9))),
                          if (m.location.isNotEmpty)
                            Text(m.location, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9))),
                        ],
                      ),
                    ),
                    const DcnSectionHeader(title: 'RSVPs'),
                    DcnCard(
                      child: Row(
                        children: [
                          DcnIcon('users', size: 18, color: c.brand),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('${m.audienceCount} invited · live RSVPs appear as your team responds',
                                style: TextStyle(fontSize: 12.5, color: c.textMuted)),
                          ),
                        ],
                      ),
                    ),
                    if (m.status == MeetingStatus.rescheduled) ...[
                      const DcnSectionHeader(title: 'Change log'),
                      DcnCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: c.warningSoft, shape: BoxShape.circle),
                              child: DcnIcon('refresh', size: 13, color: c.warning),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Rescheduled',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
                                  if ((m.reason ?? '').isNotEmpty)
                                    Text(m.reason!, style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if ((m.agenda ?? '').isNotEmpty) ...[
                      const DcnSectionHeader(title: 'Agenda'),
                      DcnCard(child: Text(m.agenda!, style: TextStyle(fontSize: 13, color: c.text, height: 1.55))),
                    ],
                  ],
                ),
              ),
            ),
            if (active)
              Container(
                decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    DcnButton(label: 'Cancel', variant: DcnButtonVariant.ghost, icon: 'x', onPressed: () => context.push('/hod/cancel/${m.id}')),
                    const SizedBox(width: 10),
                    Expanded(child: DcnButton(label: 'Reschedule', icon: 'refresh', full: true, onPressed: () => context.push('/hod/reschedule/${m.id}'))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
      );
}
