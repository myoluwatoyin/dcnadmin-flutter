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

class HodMeetingsScreen extends ConsumerStatefulWidget {
  const HodMeetingsScreen({super.key});
  @override
  ConsumerState<HodMeetingsScreen> createState() => _State();
}

class _State extends ConsumerState<HodMeetingsScreen> {
  String _view = 'upcoming';

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final all = ref.watch(hodMeetingsProvider).valueOrNull ?? const <Meeting>[];
    final filtered = all.where((m) {
      if (_view == 'upcoming') return m.status != MeetingStatus.cancelled;
      if (_view == 'rescheduled') return m.status == MeetingStatus.rescheduled;
      return m.status == MeetingStatus.cancelled;
    }).toList();

    return Column(
      children: [
        DcnHeaderBar(
          title: 'Meetings',
          sub: '${all.where((m) => m.status != MeetingStatus.cancelled).length} upcoming',
          right: [
            GestureDetector(
              onTap: () => context.push('/hod/new-meeting'),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
                child: const DcnIcon('plus', size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
        Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: DcnSegmented(
            options: const [
              (id: 'upcoming', label: 'Upcoming'),
              (id: 'rescheduled', label: 'Rescheduled'),
              (id: 'past', label: 'Cancelled'),
            ],
            value: _view,
            onChanged: (v) => setState(() => _view = v),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const DcnEmptyState(icon: 'calendar', title: 'Nothing here', body: 'No meetings in this view.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final m = filtered[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MeetingRow(meeting: m, onTap: () => context.push('/hod/meeting/${m.id}')),
                        if (m.status == MeetingStatus.rescheduled && (m.reason ?? '').isNotEmpty)
                          _banner(c, c.warningSoft, c.warning, 'Moved — ${m.reason}'),
                        if (m.status == MeetingStatus.cancelled && (m.reason ?? '').isNotEmpty)
                          _banner(c, c.dangerSoft, c.danger, 'Cancelled — ${m.reason}'),
                        if (m.status == MeetingStatus.scheduled || m.status == MeetingStatus.rescheduled)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                DcnButton(label: 'Reschedule', variant: DcnButtonVariant.ghost, size: DcnButtonSize.sm, icon: 'refresh', onPressed: () => context.push('/hod/reschedule/${m.id}')),
                                const SizedBox(width: 8),
                                DcnButton(label: 'Cancel', variant: DcnButtonVariant.ghost, size: DcnButtonSize.sm, icon: 'x', onPressed: () => context.push('/hod/cancel/${m.id}')),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _banner(DcnColors c, Color bg, Color fg, String text) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        width: double.infinity,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: TextStyle(fontSize: 11.5, color: fg, fontWeight: FontWeight.w600)),
      );
}
