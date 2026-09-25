import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_scroll_scaffold.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/meeting.dart';
import '../data/worker_providers.dart';
import '../widgets/worker_rows.dart';

class WorkerScheduleScreen extends ConsumerWidget {
  const WorkerScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsA = ref.watch(workerMeetingsProvider);
    final meetings = meetingsA.valueOrNull ?? const <Meeting>[];

    Widget header(bool scrolled) => DcnHeaderBar(
          scrolled: scrolled,
          title: 'Schedule',
          sub: '${meetings.length} upcoming',
        );

    if (meetingsA.isLoading && !meetingsA.hasValue) {
      return DcnScrollScaffold(
        header: header,
        padding: const EdgeInsets.all(16),
        child: const Center(child: Padding(
          padding: EdgeInsets.only(top: 80),
          child: CircularProgressIndicator(),
        )),
      );
    }

    if (meetings.isEmpty) {
      return Column(
        children: [
          header(false),
          const Expanded(
            child: DcnEmptyState(
              icon: 'calendar',
              title: 'No meetings yet',
              body: "Meetings your HOD schedules for your department will show up here.",
            ),
          ),
        ],
      );
    }

    return DcnScrollScaffold(
      header: header,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          for (final m in meetings)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MeetingRow(meeting: m, onTap: () => context.push('/meeting/${m.id}')),
            ),
        ],
      ),
    );
  }
}
